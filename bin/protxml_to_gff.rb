#!/usr/bin/env ruby
#
# This file is part of protk
# Original python version created by Max Grant
# Translated to ruby by Ira Cooke 29/1/2013
#
# 

require 'protk/constants'
require 'protk/protxml_to_gff_tool'
require 'protk/fastadb'
require 'libxml'
require 'bio'

include LibXML

tool=ProtXMLToGFFTool.new()

@output_extension=".gff"
@output_suffix=""

exit unless tool.check_options(true,[:database])

input_proxml=ARGV[0]

if ( tool.explicit_output!=nil)
    gff_out_file=tool.explicit_output
  else
    gff_out_file=Tool.default_output_path(input_proxml,@output_extension,tool.output_prefix,@output_suffix)
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

proteins = parse_proteins(input_proxml)
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

peptides_covered_genome={}

for prot in proteins
  prot_prob = prot['probability']
  if ( prot_prob.to_f < tool.protein_probability_threshold )
    next
  end

  # Gets identifiers of all proteins (includeing indistinguishable ones)
  prot_names=tool.protein_names(prot)


  if tool.protein_find!=nil
    prot_names=prot_names.keep_if { |pname| pname.include? tool.protein_find }  
  end


  peptides=tool.peptide_nodes(prot)
  entries_covered=[]
  for protein_name in prot_names
    protein_count += 1
    prot_id = "pr#{protein_count.to_s}"
    begin

      protein_fasta_entry = tool.get_fasta_record(protein_name,fastadb)
      protein_info = tool.cds_info_from_fasta(protein_fasta_entry) 

      unless (tool.collapse_redundant_proteins && !tool.is_new_genome_location(protein_info,entries_covered) )

        protein_gff = tool.generate_protein_gff(protein_name,protein_info,prot_prob,protein_count)

        gff_db.records += ["##gff-version 3\n","##sequence-region #{protein_info.scaffold} 1 160\n",protein_gff]

        prot_seq = protein_fasta_entry.aaseq.to_s
        throw "Not amino_acids" if prot_seq != protein_fasta_entry.seq.to_s

        peptides_covered_protein=[]
        peptide_count=1
        for peptide in peptides

          pprob = peptide['nsp_adjusted_probability'].to_f
          # puts peptide
          # puts pprob
          pep_seq = peptide['peptide_sequence']

          if ( pprob >= tool.peptide_probability_threshold && (!peptides_covered_protein.include?(pep_seq) || tool.stack_charge_states))

            dna_sequence=nil
            if !protein_info.is_sixframe
              throw "A genome is required if predicted transcripts are to be mapped" unless genomedb!=nil
              dna_sequence = tool.get_dna_sequence(protein_info,genomedb)
            end


            peptide_gff = tool.generate_gff_for_peptide_mapped_to_protein(prot_seq,pep_seq,protein_info,prot_id,pprob,peptide_count,dna_sequence,genomedb)

            unless (peptide_gff.length==0 || tool.peptide_gff_is_duplicate(peptide_gff[0],peptides_covered_genome))

              tool.add_putative_nterm_to_gff(peptide_gff,pep_seq,prot_seq,protein_info,prot_id,peptide_count,dna_sequence,genomedb)

              gff_db.records += peptide_gff

              peptides_covered_protein << pep_seq unless tool.stack_charge_states
              peptides_covered_genome[pep_seq] = peptide_gff[0].start 

              total_peptides += 1
              peptide_count+=1
            else
              puts "Duplicate peptide #{peptide_gff[0]}"
            end
#            puts gff_db.records.last
          end
        end
      else
        puts "Skipping redundant entry #{protein_name}"
        protein_count-=1 # To counter +1 prior to begin rescue end block
      end

      entries_covered<<protein_info

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
