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
      'go_entries'=>"GO Entries",
      'accessions'=>"Uniprot Accessions",
      'ncbi_taxon_id'=>"NCBI Taxon ID"
    }





# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output,:debug])
tool.option_parser.banner = "Query a swissprot flat file and output to tab delimited table.\n\nUsage: swissprot_to_table.rb [options] -d flatfile.dat queries.txt"

tool.add_value_option(:database,nil,['-d','--database file','Uniprot flatfile database containing full records for proteins'])
tool.add_value_option(:output_keys,nil,['-K','--keys keys','Filter output to only the specified keys (comma separated)'])
tool.add_boolean_option(:show_keys,false,['--show-keys','Print a list of possible values for the keys field and exit'])
tool.add_value_option(:separator,"\t",['-S','--separator sep','Separator character for output, default (tab)'])
tool.add_value_option(:array_separator,",",['-A','--array-separator sep','Array Separator character, default ,'])
tool.add_value_option(:query_separator,"\t",['--query-separator sep','Separator character for queries.txt, default is tab'])
tool.add_value_option(:id_column,1,['--id-column num','Column in queries.txt in which Uniprot Accessions are found'])


if ARGV.include? "--show-keys"
  columns.each_pair { |name, val| $stdout.write "#{name} (#{val})\n" }
  exit
end


exit unless tool.check_options(true,[:database])


$protk = Constants.instance
log_level = tool.debug ? :debug : :fatal
$protk.info_level= log_level


if tool.explicit_output
  output_fh=File.new("#{tool.explicit_output}",'w')  
else
  output_fh=$stdout
end


if tool.output_keys
  output_keys=tool.output_keys.split(",").collect { |k| k.strip }
  columns.delete_if { |key, value| !output_keys.include? key }
end


db_info=tool.database_info
database_path=db_info.path

database_index_path = "#{Pathname.new(database_path).dirname}/config.dat"

skip_index = File.exists?(database_index_path) ? true : false


swissprotdb=SwissprotDatabase.new(database_path,skip_index)


def write_entry(item_name,item,columns,tool,output_fh)
  row=[item_name]
  row << columns.keys.collect do |name| 
    colvalue = item.send(name)
    colvalue = "" unless colvalue
    colvalue = colvalue.join(tool.array_separator) if colvalue.class==Array
    colvalue
  end
  output_fh.write "#{row.join(tool.separator)}\n"
end

File.open(ARGV[0]).each_line do |line|

  begin
    query_id = line.chomp.split(tool.query_separator)[tool.id_column.to_i-1]
  rescue
    query_id = line.chomp
  end

  begin
    item = swissprotdb.get_entry_for_name(query_id)
    write_entry(query_id,item,columns,tool,output_fh)
  rescue
    $protk.log "Unable to retrieve entry for #{query_id}" , :debug
  end

end

