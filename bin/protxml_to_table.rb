#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Convert a pepXML file to a tab delimited table
#
#

require 'libxml'
require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'

include LibXML

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Convert a protXML file to a tab delimited table.\n\nUsage: protxml_to_table.rb [options] file1.protXML"

# tool.options.proteinid_regex=".*?\|.*?\|(.*)"
# tool.option_parser.on( '--regex rexpr', 'Regex' ) do |regex| 
#   tool.options.proteinid_regex=regex
# end

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

input_file=ARGV[0]

output_file = tool.explicit_output!=nil ? tool.explicit_output : nil

output_fh = output_file!=nil ? File.new("#{output_file}",'w') : $stdout


XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

protxml_parser=XML::Parser.file("#{input_file}")

protxml_ns_prefix="xmlns:"
protxml_ns="xmlns:http://regis-web.systemsbiology.net/protXML"
protxml_doc=protxml_parser.parse
if not protxml_doc.root.namespaces.default
  protxml_ns_prefix=""
  protxml_ns=nil
end


column_headers=[
	"group_number","group_probability","protein_name","protein_id","indistinguishable_proteins",
	"protein_probability","coverage","peptides",
	"num_peptides","confidence"
]

output_fh.write "#{column_headers.join("\t")}\n"


protein_groups=protxml_doc.find("//#{protxml_ns_prefix}protein_group", protxml_ns)

protein_groups.each do |protein_group| 

	proteins=protein_group.find("./#{protxml_ns_prefix}protein", protxml_ns)

	proteins.each do |protein| 

		indis_proteins=protein.find("./#{protxml_ns_prefix}indistinguishable_protein", protxml_ns)
		indis_proteins_summary=""
		indis_proteins.each { |iprot| indis_proteins_summary<<"#{iprot.attributes['protein_name']};" }

		protein_id=""
		if protein.attributes['protein_name'] =~ /.*?\|.*?\|(.*)/
			protein_id=protein.attributes['protein_name'].match(/.*?\|.*?\|(.*)/)[1]
		end

		column_values=[]

		column_values << protein_group.attributes['group_number']
		column_values << protein_group.attributes['probability']

		column_values << protein.attributes['protein_name']
		column_values << protein_id
		column_values << indis_proteins_summary
		column_values << protein.attributes['probability']
		column_values << protein.attributes['percent_coverage']
		column_values << protein.attributes['unique_stripped_peptides']
		column_values << protein.attributes['total_number_peptides']
		column_values << protein.attributes['confidence']
		output_fh.write(column_values.join("\t"))
		output_fh.write("\n")

	end
end

