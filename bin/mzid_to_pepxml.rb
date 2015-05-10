#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 8/5/2015
#
# Convert mzid to pepXML
#
#

require 'libxml'
require 'protk/constants'
require 'protk/command_runner'
require 'protk/mzidentml_doc'
require 'protk/spectrum_query'
require 'protk/tool'

include LibXML

XML.indent_tree_output=true


# Setup specific command-line options for this tool. Other options are inherited from Tool
#
tool=Tool.new([:explicit_output,:debug])
# tool.add_value_option(:minprob,0.05,['--minprob mp',"Minimum probability for psm to be included in the output"])

tool.option_parser.banner = "Convert an mzIdentML file to pep.xml\n\nUsage: mzid_to_pepxml.rb [options] file1.mzid"

exit unless tool.check_options(true)

$protk = Constants.instance
log_level = tool.debug ? "info" : "warn"
$protk.info_level= log_level

input_file=ARGV[0]

if tool.explicit_output
	output_file_name=tool.explicit_output 
else
	output_file_name=Tool.default_output_path(input_file,".pep.xml","","")
end

pep_xml_writer = PepXMLWriter.new

mzid_doc = MzIdentMLDoc.new(input_file)

spectrum_queries = mzid_doc.spectrum_queries

n_queries = spectrum_queries.length

$protk.log "Converting #{n_queries} spectrum queries", :info
$protk.log "Output will be written to #{output_file_name}", :info

i=0
n_written=0
progress_increment=1
spectrum_queries.each do |query_node|
	if i % progress_increment ==0
		$stdout.write "Scanned #{i} and read #{n_written} of #{n_queries}\r"
	end

	# require 'byebug';byebug

	query = SpectrumQuery.from_mzid(query_node)		
	pep_xml_writer.append_spectrum_query(query.as_protxml)
	n_written+=1

	i+=1

end

$protk.log "Writing #{n_written} spectrum queries to #{output_file_name}", :info

pep_xml_writer.save(output_file_name)
