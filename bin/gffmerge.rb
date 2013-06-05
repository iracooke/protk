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
require 'libxml'
require 'bio'

include LibXML

tool=Tool.new(:explicit_output=>true)
tool.option_parser.banner = "Create a gff containing peptide observations.\n\nUsage: gffmerge.rb "


tool.options.gff_predicted=nil
tool.option_parser.on( '-g filename','--gff filename', 'Predicted Data (GFF3 Format)' ) do |file| 
  tool.options.gff_predicted=file
end

tool.options.protxml=nil
tool.option_parser.on( '-p filename','--protxml filename', 'Observed Data (ProtXML Format)' ) do |file| 
  tool.options.protxml=file
end

tool.options.sixframe=nil
tool.option_parser.on( '-t filename','--sixframe filename', 'Sixframe Translations (Fasta Format)' ) do |file| 
  tool.options.sixframe=file
end

tool.options.skip_fasta_indexing=false
tool.option_parser.on('--skip-index','Don\'t index sixframe translations (Index should already exist)') do 
  tool.options.skip_fasta_indexing=true
end

tool.options.peptide_probability_threshold=0.95
tool.option_parser.on('--threshold prob','Peptide Probability Threshold (Default 0.95)') do |thresh|
  tool.options.peptide_probability_threshold=thresh.to_f
end

exit unless tool.check_options [:protxml,:sixframe]

gff_out_file="merged.gff"
if ( tool.explicit_output != nil)
  gff_out_file=tool.explicit_output
end

gff_db = Bio::GFF.new()
if ( tool.gff_predicted !=nil)
  p "Reading source gff file"
  gff_db = Bio::GFF::GFF3.new(File.open(tool.gff_predicted))
  # p gff_db.records[1].attributes
  # exit
end

f = open(gff_out_file,'w+')
gff_db.records.each { |rec| 
  f.write(rec.to_s)
}

p "Parsing proteins from protxml"
protxml_parser=XML::Parser.file(tool.protxml)
protxml_doc=protxml_parser.parse
proteins = protxml_doc.find('.//protxml:protein','protxml:http://regis-web.systemsbiology.net/protXML')


db_filename = nil
case
when Pathname.new(tool.sixframe).exist? # It's an explicitly named db  
  db_filename = Pathname.new(tool.sixframe).realpath.to_s
else
  db_filename=Constants.new.current_database_for_name(tool.sixframe)
end

db_indexfilename = "#{db_filename}.pin"

if File.exist?(db_indexfilename)
  p "Using existing indexed translations"
  orf_lookup = FastaDB.new(db_filename)
else
  p "Indexing sixframe translations"
  orf_lookup = FastaDB.create(db_filename,db_filename,'prot')
end

p "Aligning peptides and writing GFF data..."
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
  indis_proteins = prot.find('protxml:indistinguishable_protein','protxml:http://regis-web.systemsbiology.net/protXML')
  prot_names = [prot['protein_name']]
  for protein in indis_proteins
    prot_names += [protein['protein_name']]
  end

  peptides = prot.find('protxml:peptide','protxml:http://regis-web.systemsbiology.net/protXML')

  for protein_name in prot_names
    protein_count += 1
    prot_qualifiers = {"source" => "OBSERVATION", "score" => prot_prob, "ID" => 'pr' + protein_count.to_s}
    begin
      puts "Looking up #{protein_name}"
      orf = orf_lookup.get_by_id protein_name
      if ( orf == nil)
        puts "Failed lookup for #{protein_name}"
        raise KeyError
      end


      position = orf.identifiers.description.split('|').collect { |pos| pos.to_i }

      if ( position.length != 2 )
        puts "Badly formatted entry #{orf}"
        raise EncodingError
      end
      orf_name = orf.entry_id.scan(/lcl\|(.*)/)[0][0]
      frame=orf_name.scan(/frame_(\d)/)[0][0]
      scaffold_name = orf_name.scan(/(scaffold_?\d+)_/)[0][0]

      strand = (frame.to_i > 3) ? '-' : '+'
#      strand = +1

      prot_id = "pr#{protein_count.to_s}"
      prot_attributes = [["ID",prot_id],["Name",orf_name]]
      prot_gff_line = Bio::GFF::GFF3::Record.new(seqid = scaffold_name,source="OBSERVATION",feature_type="protein",
        start_position=position[0]+1,end_position=position[1],score=prot_prob,strand=strand,frame=nil,attributes=prot_attributes)
      gff_db.records += ["##gff-version 3\n","##sequence-region #{scaffold_name} 1 160\n",prot_gff_line]

      prot_seq = orf.aaseq.to_s
      throw "Not amino_acids" if prot_seq != orf.seq.to_s

      if ( strand=='-' )
        prot_seq.reverse!
      end

      for peptide in peptides
        pprob = peptide['nsp_adjusted_probability'].to_f
        if ( pprob >= tool.peptide_probability_threshold )
          total_peptides += 1
          pep_seq = peptide['peptide_sequence']

          if ( strand=='-')
            pep_seq.reverse!
          end

          start_indexes = [0]
          prot_seq.scan /#{pep_seq}/  do |match| 
              start_indexes << prot_seq.index(match,start_indexes.last)
          end
          start_indexes.delete_at(0)

          # Now convert peptide coordinate to genome coordinates
          # And create gff lines for each match
          start_indexes.collect do |si|
            pep_genomic_start = position[0] + 3*si
            pep_genomic_end = pep_genomic_start + 3*pep_seq.length - 1
            peptide_count+=1
            pep_id = "p#{peptide_count.to_s}"
            pep_attributes = [["ID",pep_id],["Parent",prot_id]]
            pep_gff_line = Bio::GFF::GFF3::Record.new(seqid = scaffold_name,source="OBSERVATION",
              feature_type="peptide",start_position=pep_genomic_start,end_position=pep_genomic_end,score=pprob,
              strand=strand,frame=nil,attributes=pep_attributes)
            fragment_gff_line = Bio::GFF::GFF3::Record.new(seqid = scaffold_name,source="OBSERVATION",
              feature_type="fragment",start_position=pep_genomic_start,end_position=pep_genomic_end,score='',
              strand=strand,frame=nil,attributes=[["Parent",pep_id],["ID",peptide['peptide_sequence']]])
            gff_db.records += [pep_gff_line,fragment_gff_line]

          end


        end
      end

    rescue KeyError,EncodingError
      skipped+=0
    end

    # p orf_name
    # p prot_gff_line
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
