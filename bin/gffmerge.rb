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

# Checking for required options
begin
  tool.option_parser.parse!
  mandatory = [:gff_predicted, :protxml,:sixframe] 
  missing = mandatory.select{ |param| tool.send(param).nil? }
  if not missing.empty?                                            
    puts "Missing options: #{missing.join(', ')}"                  
    puts tool.option_parser                                                  
    exit                                                           
  end                                                              
rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
  puts $!.to_s                                                           
  puts tool.option_parser                                              
  exit                                                                   
end


p "Parsing proteins from protxml"
protxml_parser=XML::Parser.file(tool.protxml)
protxml_doc=protxml_parser.parse
proteins = protxml_doc.find('.//protxml:protein','protxml:http://regis-web.systemsbiology.net/protXML')

p "Indexing sixframe translations"
db_filename = Pathname.new(tool.sixframe).realpath.to_s

if tool.skip_fasta_indexing 
  orf_lookup = FastaDB.new(db_filename)
else
  orf_lookup = FastaDB.create(db_filename,db_filename,'nucl')
end

p orf_lookup.get_by_id "lcl|scaffold_1_frame_1_orf_8"

p "Aligning peptides and writing GFF data..."
low_prob = 0
skipped = 0
peptide_count = 0
protein_count = 0
total_peptides = 0
for prot in proteins
  prot_prob = prot['probability']
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
      p "Looking up #{protein_name}"
      scaffold = orf_lookup.get_by_id protein_name
      if ( scaffold == nil)
        raise KeyError
      end
      p scaffold.description
      position = scaffold.description.split(' ')[1].split('|')
      scaffold_name = scaffold.entry_id.scan(/^([^_]+_[^_]+).*/)
      for peptide in peptides
        total_peptides += 1
      end
      # scaffold_name = re.findall("^([^_]+_[^_]+).*", protein.attrib['protein_name'])[0]
      # position = scaffold.description.split(' ')[1].split('|')
      # position[0] = int(position[0])
      # position[1] = int(position[1])
    rescue KeyError
      skipped+=0
      p "Lookup failed for #{protein_name}"
      exit
    end
  end

end

p "Finished."
p "Proteins: #{protein_count}"
p "Skipped Decoys: #{skipped}"
p "Total Peptides: #{total_peptides}"
p "Peptides Written: #{total_peptides - low_prob}"
p "Peptides Culled: #{low_prob}"

