#!/usr/bin/env ruby
#
# This file is part of Protk
# Created by Ira Cooke 12/4/2010
#
# Convert tandem output files to pepxml. A wrapper for Tandem2XML
#


require 'protk/constants'
require 'protk/search_tool'

# Environment with global constants
#
genv=Constants.new

tool=SearchTool.new([:explicit_output,:over_write])
tool.option_parser.banner = "Convert tandem files to pep.xml files.\n\nUsage: tandem_to_pepxml.rb [options] file1.dat file2.dat ... "

# tool.option_parser.parse!

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

binpath=%x[which Tandem2XML]
binpath.chomp!

ARGV.each do |file_name| 

  input_path=Pathname.new(file_name.chomp).realpath.to_s
  output_path="#{input_path}.pep.xml"

  if ( tool.explicit_output )
    final_output_path=tool.explicit_output
  else
    final_output_path=output_path
  end

  cmd = "#{binpath} #{input_path} #{output_path}"
    
  code = tool.run(cmd,genv)
  throw "Command #{cmd} failed with exit code #{code}" unless code==0
end