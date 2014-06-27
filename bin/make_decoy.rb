#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 9/3/2012
#
# Create a decoy database based on a set of real protein sequences
#
#

require 'libxml'
require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/randomize'
require 'tempfile'
require 'bio'

include LibXML

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Create a decoy database from real protein sequences.\n\nUsage: make_decoy.rb [options] realdb.fasta"

tool.add_value_option(:db_length,0,['-L len','--db-length len','Number of sequences to generate'])
tool.add_value_option(:prefix_string,"decoy_",['-P str','--prefix-string str','String to prepend to sequence ids'])
tool.add_boolean_option(:reverse_only,false,['--reverse-only','Just reverse sequences. Dont try to randomize. Ignores -L'])
tool.add_value_option(:id_regex,".*?\\|(.*?)[ \\|]",['--id-regex regex','Regex for finding IDs. If reverse-only is used then this will be used to find ids and prepend with the decoy string. Default .*?\\|(.*?)[ \\|]'])
tool.add_boolean_option(:append,false,['-A','--append','Append input sequences to the generated database'])

exit unless tool.check_options(true,[:explicit_output])

input_file=ARGV[0]


db_length=tool.db_length
if ( db_length==0) #If no db length was specified use the number of entries in the input file
  db_length=Bio::FastaFormat.open(input_file).count
end

output_file = tool.explicit_output if tool.explicit_output!=nil

genv=Constants.new()

decoys_tmp_file = Pathname.new(Tempfile.new("random").path).basename.to_s;

if (tool.reverse_only)
	decoys_out = File.open(decoys_tmp_file,'w+')
	Bio::FastaFormat.open(input_file).each do |seq| 
		id=nil
		begin
			# require 'debugger';debugger
			id=seq.definition.chomp.scan(/#{tool.id_regex}/)[0][0]
			revdef=seq.definition.sub(id,"#{tool.prefix_string}#{id}")
			decoys_out.write ">#{revdef}\n#{seq.aaseq}\n"
		rescue
			puts "Unable to parse id for #{seq.definition}. Skipping" if (id==nil)
		end
	end
	decoys_out.close
else
	Randomize.make_decoys input_file, db_length, decoys_tmp_file, tool.prefix_string
end

if ( tool.append )
	cmd ="awk 'FNR==1{print \"\"}1' #{input_file} #{decoys_tmp_file} > #{output_file};"
	cmd << "rm #{decoys_tmp_file}"
else
	cmd = "mv #{decoys_tmp_file} #{output_file}"
end

tool.run(cmd,genv)


