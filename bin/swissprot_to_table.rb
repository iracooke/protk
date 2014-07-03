#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Convert a pepXML file to a tab delimited table
#
#
require 'protk/tool'
require 'protk/swissprot_database'
require 'protk/bio_sptr_extensions'
require 'protk/fastadb'

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output,:database])
tool.option_parser.banner = "Query a swissprot flat file and output to tab delimited table.\n\nUsage: swissprot_to_table.rb [options] -d flatfile.dat queries.txt"

tool.add_value_option(:output_keys,nil,['-K','--keys keys','Filter output to only the specified keys'])
tool.add_value_option(:separator,"\t",['-S','--separator sep','Separator character, default (tab)'])
tool.add_value_option(:array_separator,",",['-A','--array-separator sep','Array Separator character, default ,'])

exit unless tool.check_options(true,[:database])

input_file=ARGV[0]

if tool.explicit_output
  output_fh=File.new("#{tool.explicit_output}",'w')  
else
  output_fh=$stdout
end

columns={'recname'=>"Primary Name",'cd'=>"CD Antigen Name",'altnames'=>"Alternate Names", 
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
      'go_terms'=>"GO Terms",
      'go_entries'=>"GO Entries"
    }

if tool.output_keys
  columns.delete_if { |key, value| !tool.output_keys.include? key }
end


db_info=tool.database_info
database_path=db_info.path

swissprotdb=SwissprotDatabase.new(database_path)


File.open(ARGV[0]).each_line do |line|  
  query_id = line.chomp
  item = swissprotdb.get_entry_for_name(query_id)

  if item
    row=[query_id]
    row << columns.keys.collect do |name| 
      colvalue = item.send(name)
      colvalue = "" unless colvalue
      colvalue = colvalue.join(tool.array_separator) if colvalue.class==Array
      colvalue
    end
    output_fh.write "#{row.join(tool.separator)}\n"
  end
end

