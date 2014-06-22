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

tool=SearchTool.new([:explicit_output,:over_write,:prefix])
tool.option_parser.banner = "Convert tandem files to pep.xml files.\n\nUsage: tandem_to_pepxml.rb [options] file1.dat file2.dat ... "

@output_suffix=""

exit unless tool.check_options(true)

binpath=%x[which Tandem2XML]
binpath.chomp!


ARGV.each do |filename| 

  throw "Input file #{filename} does not exist" unless File.exist?(filename)

  if ( tool.explicit_output )
    output_path=tool.explicit_output
  else
    output_path=Tool.default_output_path(filename.chomp,".pep.xml",tool.output_prefix,@output_suffix)
  end

  throw "Unable to find Tandem2XML" unless binpath=~/Tandem2XML/
  cmd = "#{binpath} #{filename.chomp} #{output_path}"
    
  code = tool.run(cmd,genv)
  throw "Command #{cmd} failed with exit code #{code}" unless code==0
end