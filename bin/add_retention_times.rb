#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Attempts to add retention times to pepxml by looking up retention times in a raw file
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'libxml'
require 'protk/mascot_util'
include LibXML

# Environment with global constants
#
genv=Constants.instance

tool=Tool.new([:over_write,:explicit_output])
tool.option_parser.banner = "Look up retention times in a raw file and \
add them to a pepxml file.\n\nUsage: add_retention_times.rb [options] file1.pep.xml file2.mgf"

exit unless tool.check_options 

if ( ARGV[0].nil? || ARGV[1].nil? )
    puts "You must supply an input pepxml file and an input mgf file"
    puts tool.option_parser 
    exit
end

pepxml_file=ARGV[0]
mgf_file=ARGV[1]

pepxml_parser=XML::Parser.file(pepxml_file)

begin
	"Creating mascot spectrum id table"
	rt_table=MascotUtil.index_mgf_times(mgf_file)
rescue
	puts "Unable to index retention times in mgf file"
	exit
end

pepxml_ns_prefix="xmlns:"
pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"

pepxml_doc=pepxml_parser.parse
if not pepxml_doc.root.namespaces.default
  pepxml_ns_prefix=""
  pepxml_ns=nil
end

queries=pepxml_doc.find("//#{pepxml_ns_prefix}spectrum_query", pepxml_ns)

queries.each do |query|

	atts=query.attributes
	spect=atts["spectrum"]


	throw "No spectrum found for spectrum_query #{query}" unless ( spect!=nil)

	retention_time = rt_table[spect]
	if retention_time==nil
		retention_time=rt_table[spect.chop]
		if retention_time==nil
			retention_time=rt_table[spect.chop.chop]
		end
	end
	if ( retention_time!=nil)
      
		if ( query.attributes["retention_time_sec"]!=nil )
			puts "A retention time value is already present" 
			exit
		end

		if ( query.attributes["retention_time_sec"]==nil || over_write)
			query.attributes["retention_time_sec"]=retention_time       
     		# p queries[i].attributes["retention_time_sec"] 
     	end
    else 
    		puts "No retention time found for spectrum #{spect}"
	end
end

if tool.explicit_output.nil? 
	pepxml_doc.save(pepxml_file)	
else
	pepxml_doc.save(tool.explicit_output)
end


