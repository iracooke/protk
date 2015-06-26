#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 22/5/2015
#
# Filters a fasta file so only entries matching a condition are emitted
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'set'
require 'bio'

tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Filter entries in a fasta file.\n\nUsage: filter_fasta.rb [options] file.fasta file2.fasta"
tool.add_value_option(:definition_filter,nil,['--definition filter','Keep entries matching definition'])
tool.add_boolean_option(:invert,false,['--invert',"Invert Filter"])
tool.add_value_option(:id_filter,nil,['-I filename','--id-filter filename',"Keep entries with given identifiers"])

exit unless tool.check_options(true)

input_file=ARGV[0]

output_fh = tool.explicit_output!=nil ? File.new("#{tool.explicit_output}",'w') : $stdout

$filter_ids = Set.new()
if tool.id_filter && (File.exists?(tool.id_filter) || tool.id_filter=="-")
	if tool.id_filter=="-"
		# require 'byebug';byebug
		$filter_ids = $stdin.read.split("\n").collect { |e| e.chomp }
	else
		$filter_ids = File.readlines(tool.id_filter).collect { |e| e.chomp }
	end
	$filter_ids = Set.new($filter_ids) # Much faster set include than array include
end

def passes_filters(entry,tool)

	if tool.definition_filter
		if entry.definition =~ /#{tool.definition_filter}/
			return true
		else
			return false
		end
	end

	if $filter_ids.length > 0
		require 'byebug';byebug

		if $filter_ids.include? entry.entry_id
			return true
		end
		return false
	end

	# Always true if there are no filters defined

	return true

end


ARGV.each do |fasta_file|

	file = Bio::FastaFormat.open(fasta_file.chomp)
	file.each do |entry|


		pass = passes_filters(entry,tool)
		pass = !pass if tool.invert
		if pass
			output_fh.write entry
		end
	end
end
