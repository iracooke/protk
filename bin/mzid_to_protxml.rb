#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 7/5/2015
#
# Convert mzid to protXML
#
#

require 'libxml'
require 'protk/constants'
require 'protk/command_runner'
require 'protk/mzidentml_doc'
require 'protk/protein_group'
require 'protk/tool'

include LibXML

XML.indent_tree_output=true


# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output,:debug])
tool.add_value_option(:minprob,0.05,['--minprob mp',"Minimum probability for protein to be included in the output"])

tool.option_parser.banner = "Convert an mzIdentML file to protXML.\n\nUsage: mzid_to_protxml.rb [options] file1.mzid"

exit unless tool.check_options(true)

$protk = Constants.instance
log_level = tool.debug ? "info" : "warn"
$protk.info_level= log_level

input_file=ARGV[0]

if tool.explicit_output
	output_file_name=tool.explicit_output 
else
	output_file_name=Tool.default_output_path(input_file,".protXML","","")
end

prot_xml_writer = ProtXMLWriter.new

mzid_doc = MzIdentMLDoc.new(input_file)

protein_groups = mzid_doc.protein_groups

n_prots = protein_groups.length

$protk.log "Converting #{n_prots} protein_groups", :info
$protk.log "Output will be written to #{output_file_name}", :info

i=0
n_written=0
progress_increment=1
protein_groups.each do |group_node|
	if i % progress_increment ==0
		$stdout.write "Scanned #{i} and read #{n_written} of #{n_prots}\r"
	end

	# require 'byebug';byebug
	group_prob = MzIdentMLDoc.get_cvParam(group_node,"MS:1002470").attributes['value'].to_f*0.01

	if group_prob > tool.minprob.to_f
		group = ProteinGroup.from_mzid(group_node)		
		prot_xml_writer.append_protein_group(group.as_protxml)
		n_written+=1
	end

	i+=1

end

$protk.log "Writing #{n_written} proteins to #{output_file_name}", :info

prot_xml_writer.save(output_file_name)
