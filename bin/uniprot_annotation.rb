#!/usr/bin/env ruby
#
# This file is part of Protk
# Created by Ira Cooke 24/3/2013
#
# Retrieve annotation information for proteins from the Uniprot Swissprot database
#
# 
require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/swissprot_database'
require 'protk/bio_sptr_extensions'


# Setup specific command-line options for this tool. Other options are inherited from Tool
#
tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Retrieve information from the Uniprot database given a list of ID's.\n\n\
Usage: uniprot_annotation.rb [options] input.tsv"

tool.options.id_column=1
tool.option_parser.on(  '--id-column num', 'Specify a column for ids (default is column 1)' ) do |col|
  tool.options.id_column=col.to_i
end

tool.options.flatfiledb="swissprot"
tool.option_parser.on(  '--flatfiledb dbname', 'Specify path to a Uniprot flatfile' ) do |dbname|
  tool.options.flatfiledb=dbname
end

tool.options.fields=nil
tool.option_parser.on(  '--fields flds', 'A comma separated list of fields to extract' ) do |flds|
  tool.options.fields=flds
end

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

# Obtain a global environment object
genv=Constants.new

input_file=ARGV[0]

swissprotdb=SwissprotDatabase.new(genv,tool.flatfiledb)

output_file=nil

if ( tool.explicit_output==nil)
  output_file=$stdout
else
  output_file=File.open(tool.explicit_output,'w+')
end

ac_column = tool.id_column-1

db_fields = {
  'recname'=>"Primary Name",
  'cd'=>"CD Antigen Name",
  'altnames'=>"Alternate Names", 
  'location' => "Subcellular Location",
  'function' => "Known Function",
  'similarity' => "Similarity",
  'tissues' => "Tissue Specificity",
  'disease' => "Disease Association",
  'domain' => "Domain",
  'subunit' => "Sub Unit",
  'nextbio' => "NextBio",
  'ipi' => "IPI",
  'intact' => "Interactions",
  'pride' => 'Pride',
  'ensembl'=> 'Ensembl',
  'num_transmem'=>"Transmembrane Regions",
  'signalp'=>'Signal Peptide',
  'ref_dump'=>'References',
  'tax_dump'=>'Taxonomy Cross Ref',
  'species_dump'=>'Species',
  'feature_dump'=>'Feature Table',
  'seq_dump' => 'AA Sequence'
  }

hyperlink_fields = {
  'uniprot_link'=>"Uniprot Link",
  'nextbio_link'=>'NextBio Link',
  'intact_link'=>"Interactions Link",
  'pride_link'=>"Pride Link",
  'ensembl_link'=>"Ensembl Link"
}

if tool.fields !=nil
  fields = tool.fields.split(",").collect { |f| f.lstrip.rstrip }.reject {|e| e.empty? }
  db_fields = db_fields.select { |k| fields.include? k }
  hyperlink_fields = hyperlink_fields.select { |k| fields.include? k}
end

output_file.write db_fields.values.join("\t")
if ( hyperlink_fields.count > 0 )
  output_file.write("\t")
  output_file.write hyperlink_fields.values.join("\t")
end
output_file.write("\n")

line_num=0
File.foreach(input_file) { |line|  
  input_cols=line.split("\t")
  throw "Not enough columns in line #{line_num}" unless input_cols.count > ac_column
  accession=input_cols[ac_column].chomp

  sptr_entry=swissprotdb.get_entry_for_name(accession)

  if ( sptr_entry==nil)
    genv.log("No entry for #{accession} in uniprot database",:warn)  
  else

    db_values = db_fields.collect { |key,value|     
      sptr_entry.send(key)
    }

    hyperlink_values = hyperlink_fields.collect { |key,value|
      sptr_entry.send(key)
    }

    output_file.write db_values.join("\t")
    if ( hyperlink_fields.count > 0 )
      output_file.write("\t")
      output_file.write hyperlink_values.join("\t")
    end
    output_file.write "\n"
  end

  line_num+=1

}



