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
  attr_accessor :coding_sequences
  attr_accessor :is_sixframe
end

def cds_info_from_fasta(fasta_entry)
  info=CDSInfo.new
  info.fasta_id=fasta_entry
  positions = fasta_entry.identifiers.description.split(' ').collect { |coords| coords.split('|').collect {|pos| pos.to_i} }
  info.coding_sequences=[]

  if ( positions.length < 1 )
    raise EncodingError
  elsif ( positions.length > 1)
    info.coding_sequences = positions[1..-1]
  end

  info.start = positions[0][0]
  info.end = positions[0][1]

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
    aln=GappedAligner.new().align(pep_seq,gene_seq)
    unless aln.gaps.length==1
      puts "More than one intron.#{aln}" 
      require 'debugger';debugger
    end
    pep_coords = []
    frags = aln.fragments
    frags.reverse!  if protein_info.strand=='-'

    frags.each { |frag|  
      if protein_info.strand=='+'
        frag_genomic_start = protein_info.start + frag[0]
        frag_genomic_end = protein_info.start + frag[1]        
      else
        frag_genomic_start = protein_info.end - frag[1]
        frag_genomic_end = protein_info.end - frag[0]        
      end
      pep_coords << frag_genomic_start
      pep_coords << frag_genomic_end
    }

    return [pep_coords]
  end
end

def fragment_coords_from_protein_coords(pepstart,pepend,gene_start,gene_end,coding_sequences)
  
  sorted_cds = coding_sequences.sort { |a, b| a[0] <=> b[0] }

  # Assume positive strand
  pi_start=pepstart*3+gene_start-1
  pi_end=pepend*3+gene_start-1

  fragments=[]
  p_i = pi_start #Initially we are looking for the first fragment
  finding_start=true

  sorted_cds.each_with_index do |cds_coords, i|
    cds_start=cds_coords[0]
    cds_end = cds_coords[1]
    if cds_end < p_i # Exon is before index in sequence and doesn't contain p_i
      if sorted_cds.length <= i+1
        require 'debugger';debugger
      end

      next_coords = sorted_cds[i+1]
      intron_offset = ((next_coords[0]-cds_end)-1)
      p_i+=intron_offset
      pi_end+=intron_offset
      if !finding_start
        # This is a middle exon
        fragments << [cds_start,cds_end]
      end
    else 
      if finding_start
        fragments << [p_i+1,(cds_end)]
        next_coords = sorted_cds[i+1]
        intron_offset = ((next_coords[0]-cds_end)-1)
        p_i+=intron_offset
        pi_end+=intron_offset
        p_i = pi_end
        finding_start=false
      else # A terminal exon
#        require 'debugger';debugger
        fragments << [(cds_start),(p_i)]
        break;
      end
    end
  end
  [fragments]
end

# gene_seq should already have been reverse_complemented if on reverse strand
def get_peptide_coordinates_from_transcript_info(prot_seq,pep_seq,protein_info,gene_seq)
  if ( peptide_is_in_sixframe(pep_seq,gene_seq))
    return nil
  else

    # puts "Found a gap #{protein_info.fasta_id}"
    if protein_info.strand=='-'
      pep_index = prot_seq.reverse.index(pep_seq.reverse)
      if pep_index==nil
#        require 'debugger';debugger
        puts "Warning: Unable to find peptide #{pep_seq} in this protein! #{protein_info}"
        return nil
      end
      pep_start_i = prot_seq.reverse.index(pep_seq.reverse)+1
      # Plus 1 because on reverse stand stop-codon will be at the beginning of the sequence (when read forwards). Need to eliminate it.
    else
      pep_start_i = prot_seq.index(pep_seq)
      if pep_start_i==nil
#        require 'debugger';debugger
        puts "Warning: Unable to find peptide #{pep_seq} in this protein! #{protein_info}"
        return nil
      end
    end
    pep_end_i = pep_start_i+pep_seq.length

    return fragment_coords_from_protein_coords(pep_start_i,pep_end_i,protein_info.start,protein_info.end,protein_info.coding_sequences)
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
    [[pep_genomic_start,pep_genomic_end]]  
  end

end

# Returns a 4-mer [genomic_start,fragment1_end(or0),frag2_start(or0),genomic_end]
def get_peptide_coordinates(prot_seq,pep_seq,protein_info,gene_seq)
  if ( protein_info.is_sixframe)
    return get_peptide_coordinates_sixframe(prot_seq,pep_seq,protein_info)
  else
    return get_peptide_coordinates_from_transcript_info(prot_seq,pep_seq,protein_info,gene_seq)
  end
end


def generate_fragment_gffs_for_coords(coords,protein_info,pep_id,peptide_seq,genomedb,name="fragment")
  scaff = get_fasta_record(protein_info.scaffold,genomedb)
  scaffold_seq = Bio::Sequence::NA.new(scaff.seq)

  all_aaseqs=nil

  fragment_sense=0
  gff_lines = coords.collect do |frag_start,frag_end|
    frag_aaseq = scaffold_seq[frag_start-1..frag_end-1]
    all_aaseqs += frag_aaseq unless all_aaseqs == nil
    all_aaseqs = frag_aaseq if all_aaseqs==nil

    begin
      frag_frame = fragment_sense+1
      frag_seq = nil
      if ( protein_info.strand=='-')
        frag_seq = frag_aaseq.reverse_complement.translate(frag_frame)
      else
        frag_seq = frag_aaseq.translate(frag_frame)
      end
    rescue
      if frag_aaseq.length > 1
        puts "Unable to translate #{frag_aaseq}"
#        require 'debugger'        
      end
      frag_seq="*"
    end

    Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
        feature_type=name,start_position=frag_start,end_position=frag_end,score='',
        strand=protein_info.strand,frame=fragment_sense,attributes=[["Parent",pep_id],["ID",frag_seq]])

    fragment_sense=(fragment_sense+frag_aaseq.length) % 3

  end

  check_seq = protein_info.strand=='-' ? all_aaseqs.reverse_complement.translate : all_aaseqs.translate
  if ( check_seq != peptide_seq)
    require 'debugger';debugger
    puts "Fragment seqs not equal to peptide seqs"
  end

  return gff_lines

end

def get_start_codon_coords_for_peptide(peptide_genomic_start,peptide_genomic_end,peptide_seq,protein_seq,strand)
  pi=protein_seq.index(peptide_seq)
  if ( protein_seq[pi]=='M' )

    start_codon_coord = (strand=='+') ? peptide_genomic_start : peptide_genomic_end-1
    # require 'debugger';debugger
    return [start_codon_coord,start_codon_coord+2]
  else
    return nil
  end
end

def get_cterm_coords_for_peptide(peptide_genomic_start,peptide_genomic_end,peptide_seq,protein_seq,strand)

  if ( (peptide_seq[-1]!='K' && peptide_seq[-1]!='R' ) )

    codon_coord = (strand=='+') ? peptide_genomic_end-3 : peptide_genomic_start+1
    # require 'debugger';debugger
    return [codon_coord,codon_coord+2]
  else
    return nil
  end
end


def get_signal_peptide_for_peptide(peptide_seq,protein_seq)
  pi=protein_seq.index(peptide_seq)
  if ( pi>0 && (protein_seq[pi-1]!='K' && protein_seq[pi-1]!='R' && protein_seq[pi]!='M') )
    reverse_leader_seq=protein_seq[0..pi].reverse
    mi=reverse_leader_seq.index('M')

    if ( mi==nil )
      puts "No methionine found ahead of peptide sequence. Unable to determine signal peptide sequence"
      return nil
    end

    mi=pi-mi

    return protein_seq[mi..(pi-1)]
  else
    return nil
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

  if ( peptide_coords==nil ) # Return value of nil means the entry is a predicted transcript that should already be covered by 6-frame
    return []
  end

  gff_records=[]
  peptide_count=0

  # Now convert peptide coordinate to genome coordinates
  # And create gff lines for each match
  peptide_coords.collect do |coords|

#    require 'debugger';debugger
    pep_genomic_start = coords.first[0]
    pep_genomic_end = coords.last[1]

    peptide_count+=1
    pep_id = "#{prot_id}.p#{peptide_count.to_s}"
    pep_attributes = [["ID",pep_id],["Parent",prot_id]]

    pep_gff_line = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
      feature_type="peptide",start_position=pep_genomic_start,end_position=pep_genomic_end,score=peptide_prob,
      strand=protein_info.strand,frame=nil,attributes=pep_attributes)

    # For standard peptides
    gff_records += [pep_gff_line] + generate_fragment_gffs_for_coords(coords,protein_info,pep_id,peptide_seq,genomedb)

    # For peptides with only 1 tryptic terminus
    start_codon_coords=get_start_codon_coords_for_peptide(pep_genomic_start,pep_genomic_end,peptide_seq,protein_seq,protein_info.strand)
    if start_codon_coords
      start_codon_gff = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
        feature_type="start_codon",start_position=start_codon_coords[0],end_position=start_codon_coords[1],score='',
        strand=protein_info.strand,frame=nil,attributes=pep_attributes)
      gff_records+=[start_codon_gff]
    end

    cterm_coords = get_cterm_coords_for_peptide(pep_genomic_start,pep_genomic_end,peptide_seq,protein_seq,protein_info.strand)
    if ( cterm_coords )
      cterm_gff = Bio::GFF::GFF3::Record.new(seqid = protein_info.scaffold,source="OBSERVATION",
        feature_type="cterm",start_position=cterm_coords[0],end_position=cterm_coords[1],score='',
        strand=protein_info.strand,frame=nil,attributes=pep_attributes)
      gff_records+=[start_codon_gff]
    end

    signal_peptide = get_signal_peptide_for_peptide(peptide_seq,protein_seq)
    if signal_peptide
      # require 'debugger';debugger

      signal_peptide_coords=get_peptide_coordinates(prot_seq,signal_peptide,protein_info,dna_sequence)
      if signal_peptide_coords
        signal_peptide_coords.each do |spcoords|  
          signal_peptide_gff = generate_fragment_gffs_for_coords(spcoords,protein_info,pep_id,signal_peptide,genomedb,"signalpeptide")
          gff_records += signal_peptide_gff
        end
      end
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
