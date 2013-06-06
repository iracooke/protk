#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an id mapping query using the uniprot.org id mapping service
#
$VERBOSE=nil
require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/uniprot_mapper'

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
tool=Tool.new([:explicit_output])

tool.options.id_column=1
tool.option_parser.on(  '--id-column num', 'Specify a column for ids (default is column 1)' ) do |col|
  tool.options.id_column=col.to_i
end

tool.options.output_ids=[]
tool.option_parser.on(  '--to-id id', 'Specify an ID to output. Can be used multiple times.' ) do |id|
  tool.options.output_ids.push id
end

tool.option_parser.banner = "Given a set of IDs convert them to a different type of ID\n\nUsage: uniprot_mapper.rb input_file.txt fromID_type"

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end


from_file=ARGV.shift
throw "Must specify a file with IDs to convert" unless from_file!=nil

from_id_type=ARGV.shift
throw "Must specify a from ID type" unless from_id_type!=nil

throw "Must specify exactly 1 output id" unless tool.output_ids.length == 1

from_ids=[]
File.foreach(from_file) { |line|  
  from_ids.push line.split("\t")[tool.id_column-1].chomp
}

throw "No query ids in input file" unless from_ids.length > 0

batch_size = 500

output_id = tool.output_ids[0]

# Create output file
output_file="#{from_file}.map.txt"

output_file = tool.explicit_output if tool.explicit_output!=nil

output_fh=File.new("#{output_file}",'w')

output_fh.write "#{from_id_type}\t#{output_id}\n"

batches = (from_ids.length.to_f/batch_size.to_f).ceil

(0...batches).each do |b|  

  batch_from_ids = from_ids.shift(batch_size)

  results = UniprotMapper.new.map(from_id_type,batch_from_ids,output_id)

  result_rows = results.split("\n")
  result_rows.shift
  result_rows.each do |row|
    output_fh.write "#{row}\n"
  end

end

output_fh.close
