#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 24/6/2015
#
# Filters a pepxml file by removing or keeping only psms that match a filter
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'bio'
require 'libxml'

include LibXML

tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Filter psms in a pepxml file.\n\nUsage: filter_psms.rb [options] expression file.pepxml"
tool.add_value_option(:keep_filter,"protein",['-A','--attribute name',"Match expression against a specific attribute"])

exit unless tool.check_options(true,[:keep_filter])

if ARGV.length!=2
  puts "Wrong number of arguments. You must supply a filter expression and a pepxml file"
  exit(1)
end

expression=ARGV[0]
input_file=ARGV[1]

output_fh = tool.explicit_output!=nil ? File.new("#{tool.explicit_output}",'w') : $stdout

XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

pepxml_parser=XML::Parser.file("#{input_file}")

pepxml_ns_prefix="xmlns:"
pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"
pepxml_doc=pepxml_parser.parse
unless pepxml_doc.root.namespaces.default
  pepxml_ns_prefix=""
  pepxml_ns=nil
end


reader = XML::Reader.file(input_file)

while reader.read

    if reader.name=="msms_pipeline_analysis"
      puts reader.name
      reader.read_inner_xml()
    else
      require 'byebug';byebug
      puts reader.name
      output_fh.write reader.read_inner_xml()
    end
end

exit(1)


require 'byebug';byebug

spectrum_queries=pepxml_doc.find("//#{pepxml_ns_prefix}search_hit[@hit_rank=\"1\"]", pepxml_ns)

spectrum_queries.each do |query|
  require 'byebug';byebug
  puts query

end

output_fh.close
