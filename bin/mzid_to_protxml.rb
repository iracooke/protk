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
require 'protk/tool'

include LibXML

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Convert an mzIdentML file to protXML.\n\nUsage: mzid_to_protxml.rb [options] file1.mzid"

exit unless tool.check_options(true)

input_file=ARGV[0]

if tool.explicit_output
  output_fh=File.new("#{tool.explicit_output}",'w')  
else
  output_fh=$stdout
end

# XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

# mzid_parser=XML::Parser.file("#{input_file}")

# pepxml_ns_prefix="xmlns:"
# pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"
#  pepxml_doc=pepxml_parser.parse
# if not pepxml_doc.root.namespaces.default
#   pepxml_ns_prefix=""
#   pepxml_ns=nil
# end


output_fh.close