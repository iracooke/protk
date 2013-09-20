#!/usr/bin/env ruby
#
# This file is part of protk
# Original python version created by Max Grant
# Translated to ruby by Ira Cooke 29/1/2013
#
# 

require 'protk/constants'
require 'protk/tool'
require 'protk/fastadb'
require 'protk/gapped_aligner'
require 'libxml'
require 'bio'

include LibXML

tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Create a gff containing peptide observations.\n\nUsage: protxml_to_gff.rb "


tool.options.protxml=nil
tool.option_parser.on( '-p filename','--protxml filename', 'Observed Data (ProtXML Format)' ) do |file| 
  tool.options.protxml=file
end

tool.options.database=nil
tool.option_parser.on( '-d filename','--database filename', 'Database used for ms/ms searches (Fasta Format)' ) do |file| 
  tool.options.database=file
end

tool.options.genome=nil
tool.option_parser.on( '-g filename','--genome filename', 'Nucleotide sequences for scaffolds (Fasta Format)' ) do |file| 
  tool.options.genome=file
end

tool.options.skip_fasta_indexing=false
tool.option_parser.on('--skip-index','Don\'t index database (Index should already exist)') do 
  tool.options.skip_fasta_indexing=true
end

tool.options.peptide_probability_threshold=0.95
tool.option_parser.on('--threshold prob','Peptide Probability Threshold (Default 0.95)') do |thresh|
  tool.options.peptide_probability_threshold=thresh.to_f
end

exit unless tool.check_options [:protxml,:database]

gff_out_file="peptides.gff"
if ( tool.explicit_output != nil)
  gff_out_file=tool.explicit_output
end

gff_db = Bio::GFF.new()
f = open(gff_out_file,'w+')


def parse_proteins(protxml_file)
  puts "Parsing proteins from protxml"
  protxml_parser=XML::Parser.file(protxml_file)
  protxml_doc=protxml_parser.parse
  proteins = protxml_doc.find('.//protxml:protein','protxml:http://regis-web.systemsbiology.net/protXML')
  proteins
end

def prepare_fasta(database_path,type)
  db_filename = nil
  case
  when Pathname.new(database_path).exist? # It's an explicitly named db  
    db_filename = Pathname.new(database_path).realpath.to_s
  else
    db_filename=Constants.new.current_database_for_name(database_path)
  end

  db_indexfilename = "#{db_filename}.pin"

  if File.exist?(db_indexfilename)
    puts "Using existing indexed database"
    orf_lookup = FastaDB.new(db_filename)
  else
    puts "Indexing database"
    orf_lookup = FastaDB.create(db_filename,db_filename,type)
  end
  orf_lookup
end

def protein_names(protein_node)
  indis_proteins = protein_node.find('protxml:indistinguishable_protein','protxml:http://regis-web.systemsbiology.net/protXML')
  prot_names = [protein_node['protein_name']]
  for protein in indis_proteins
    prot_names += [protein['protein_name']]
  end
  prot_names
end

def peptide_nodes(protein_node)
  protein_node.find('protxml:peptide','protxml:http://regis-web.systemsbiology.net/protXML')
end


def get_fasta_record(protein_name,fastadb)
#  puts "Looking up #{protein_name}"
  entry = fastadb.get_by_id protein_name
  if ( entry == nil)
    puts "Failed lookup for #{protein_name}"
    raise KeyError
  end
  entry
end

class CDSInfo
  attr_accessor :fasta_id
  attr_accessor :strand
  attr_accessor :frame
  attr_accessor :name
  attr_accessor :scaffold
  attr_accessor :start
  attr_accessor :end
  attr_accessor :is_sixframe
end

def cds_info_from_fasta(fasta_entry)
  info=CDSInfo.new
  info.fasta_id=fasta_entry
  positions = fasta_entry.identifiers.description.split('|').collect { |pos| pos.to_i }

  if ( positions.length != 2 )
    puts "Badly formatted fasta_entry #{fasta_entry}"
    raise EncodingError
  end

  info.start = positions[0]
  info.end = positions[1]

  info.scaffold=fasta_entry.entry_id.scan(/(scaffold_?\d+)_/)[0][0]
  info.name = fasta_entry.entry_id.scan(/lcl\|(.*)/)[0][0]

  if fasta_entry.entry_id =~ /frame/
    info.frame=info.name.scan(/frame_(\d)/)[0][0]
    info.strand = (info.frame.to_i > 3) ? '-' : '+'
    info.is_sixframe = true
  else
    info.strand = (info.name =~ /rev/) ? '-' : '+'
    info.is_sixframe = false
  end
  info
end

def generate_protein_gff(protein_name,entry_info,prot_prob,prot_id)
  prot_qualifiers = {"source" => "OBSERVATION", "score" => prot_prob, "ID" => prot_id}
  prot_attributes = [["ID",prot_id],["Name",entry_info.name]]
  prot_gff_line = Bio::GFF::GFF3::Record.new(seqid = entry_info.scaffold,source="OBSERVATION",feature_type="protein",
    start_position=entry_info.start+1,end_position=entry_info.end,score=prot_prob,strand=entry_info.strand,frame=nil,attributes=prot_attributes)
  prot_gff_line
end

def get_dna_sequence(protein_info,genomedb)

  scaffold_sequence = get_fasta_record(protein_info.scaffold,genomedb)
  gene_sequence = scaffold_sequence.naseq.to_s[(protein_info.start-1)..protein_info.end]

  if ( protein_info.strand == "-")
    gene_sequence = Bio::Sequence::NA.new(gene_sequence).reverse_complement
  end

  gene_sequence
end

def peptide_is_in_sixframe(pep_seq,gene_seq)
  gs=Bio::Sequence::NA.new(gene_seq)
  (1..6).each do |frame|  
    if gs.translate(frame).index(pep_seq)
      return true
    end
  end
  return false
end

# gene_seq should already have been reverse_complemented if on reverse strand
def get_peptide_coordinates_by_alignment(prot_seq,pep_seq,protein_info,gene_seq)
  if ( peptide_is_in_sixframe(pep_seq,gene_seq))
    return nil
  else
    puts "Warning. Actually found a gap #{protein_info.fasta_id}"
    require 'debugger';debugger
    aln=GappedAligner.new().align(pep_seq,gene_seq)
    throw "More than one intron.#{aln}" unless aln.gaps.length==1

    frags = aln.fragments
    pep_coords=[frags[0][0],frags[0][1],frags[1][0],frags[1][1]]
    if ( protein_info.strand == '-' )
      prot_seq = prot_seq.reverse
      pep_seq = pep_seq.reverse
    end

    return [0,0,0,0]
  end
end

def get_peptide_coordinates_sixframe(prot_seq,pep_seq,protein_info)

  if ( protein_info.strand == '-' )
    prot_seq = prot_seq.reverse
    pep_seq = pep_seq.reverse
  end

  start_indexes = [0]
  
  prot_seq.scan /#{pep_seq}/  do |match| 
  start_indexes << prot_seq.index(match,start_indexes.last)
  end  
  start_indexes.delete_at(0)

  start_indexes.collect do |si| 
    pep_genomic_start = protein_info.start + 3*si
    pep_genomic_end = pep_genomic_start + 3*pep_seq.length - 1
    [pep_genomic_start,0,0,pep_genomic_end]  
  end

end

# Returns a 4-mer [genomic_start,fragment1_end(or0),frag2_start(or0),genomic_end]
def get_peptide_coordinates(prot_seq,pep_seq,protein_info,gene_seq)
  if ( protein_info.is_sixframe)
    return get_peptide_coordinates_sixframe(prot_seq,pep_seq,protein_info)
  else
    return get_peptide_coordinates_by_alignment(prot_seq,pep_seq,protein_info,gene_seq)
  end
end

def generate_gff_for_peptide_mapped_to_protein(protein_seq,peptide_seq,protein_info,prot_id,peptide_prob,genomedb=nil)

  dna_sequence=nil
  if !protein_info.is_sixframe
    throw "A genome is required if predicted transcripts are to be mapped" unless genomedb!=nil
    dna_sequence = get_dna_sequence(protein_info,genomedb)
  end

  prot_seq = protein_seq
  pep_seq = peptide_seq


  peptide_coords = get_peptide_coordinates(prot_seq,pep_seq,protein_info,dna_sequence)  

  if ( peptide_coords==nil ) # In 6-frame so no need to write this entry
    return []
  end

  gff_records=[]
  peptide_count=0

  # Now convert peptide coordinate to genome coordinates
  # And create gff lines for each match
  peptide_coords.collect do |pep_genomic_start,frag1_end,frag2_start,pep_genomic_end|
    
    peptide_count+=1
    pep_id = "#{prot_id}.p#{peptide_count.to_s}"
    pep_attributes = [["ID",pep_id],["Parent",prot_id]]

    pep_gff_line = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
      feature_type="peptide",start_position=pep_genomic_start,end_position=pep_genomic_end,score=peptide_prob,
      strand=protein_info.strand,frame=nil,attributes=pep_attributes)

    if frag1_end==0
      fragment_gff_line = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
        feature_type="frag",start_position=pep_genomic_start,end_position=pep_genomic_end,score='',
        strand=protein_info.strand,frame=nil,attributes=[["Parent",pep_id],["ID",peptide_seq]])
      gff_records += [pep_gff_line,fragment_gff_line]
    else
      fragment_gff_line1 = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
        feature_type="frag",start_position=pep_genomic_start,end_position=frag1_end,score='',
        strand=protein_info.strand,frame=nil,attributes=[["Parent",pep_id],["ID",peptide_seq]])

      fragment_gff_line2 = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
        feature_type="frag",start_position=frag2_start,end_position=pep_genomic_end,score='',
        strand=protein_info.strand,frame=nil,attributes=[["Parent",pep_id],["ID",peptide_seq]])

      gff_records += [pep_gff_line,fragment_gff_line1,fragment_gff_line2]
    end

  end
  gff_records

end

proteins = parse_proteins(tool.protxml)
fastadb = prepare_fasta(tool.database,'prot')
genomedb = nil
if tool.genome
  genomedb = prepare_fasta(tool.genome,'nucl')
end

puts "Aligning peptides and writing GFF data..."

low_prob = 0
skipped = 0
peptide_count = 0
protein_count = 0
total_peptides = 0

for prot in proteins
  prot_prob = prot['probability']
  if ( prot_prob.to_f < tool.peptide_probability_threshold )
    next
  end

  # Gets identifiers of all proteins (includeing indistinguishable ones)
  prot_names=protein_names(prot)

  peptides=peptide_nodes(prot)

  for protein_name in prot_names
    protein_count += 1
    prot_id = "pr#{protein_count.to_s}"
    begin

      protein_fasta_entry = get_fasta_record(protein_name,fastadb)

      protein_info = cds_info_from_fasta(protein_fasta_entry)

      protein_gff = generate_protein_gff(protein_name,protein_info,prot_prob,protein_count)

      gff_db.records += ["##gff-version 3\n","##sequence-region #{protein_info.scaffold} 1 160\n",protein_gff]

      prot_seq = protein_fasta_entry.aaseq.to_s
      throw "Not amino_acids" if prot_seq != protein_fasta_entry.seq.to_s

      for peptide in peptides
        pprob = peptide['nsp_adjusted_probability'].to_f
        if ( pprob >= tool.peptide_probability_threshold )
          total_peptides += 1
          pep_seq = peptide['peptide_sequence']

          gff_db.records += generate_gff_for_peptide_mapped_to_protein(prot_seq,pep_seq,protein_info,prot_id,pprob,genomedb)

        end
      end
#      puts protein_gff
#      puts gff_db.records
    rescue KeyError,EncodingError
      skipped+=0
    end

    # exit
  end

end

f = open(gff_out_file,'w+')
gff_db.records.each { |rec| 
  f.write(rec.to_s)
}
f.close

p "Finished."
p "Proteins: #{protein_count}"
p "Skipped Decoys: #{skipped}"
p "Total Peptides: #{total_peptides}"
p "Peptides Written: #{total_peptides - low_prob}"
p "Peptides Culled: #{low_prob}"
exit(0)
