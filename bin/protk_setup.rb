#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 20/10/2012
#
# Post-install setup for protk. 
# Installs third party tools
#

require 'protk/constants'
require 'protk/setup_tool'
require 'yaml'
require 'pp'


# Setup specific command-line options for this tool. Other options are inherited from Tool
#
tool=SetupTool.new
tool.option_parser.banner = "Post install tasks for protk.\nUsage: protk_setup.rb [options] toolname"

tool.option_parser.parse!

if ( ARGV.length < 1)
	p "You must supply a setup task [all,system_packages]"
	p tool.option_parser
	exit
end

# Checking for required options
# begin
#   tool.option_parser.parse!
#   mandatory = [:gff_predicted, :protxml,:sixframe] 
#   missing = mandatory.select{ |param| tool.send(param).nil? }
#   if not missing.empty?                                            
#     puts "Missing options: #{missing.join(', ')}"                  
#     puts tool.option_parser                                                  
#     exit                                                           
#   end                                                              
# rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
#   puts $!.to_s                                                           
#   puts tool.option_parser                                              
#   exit                                                                   
# end


# Create install directory if it doesn't already exist
#
env=Constants.new

ARGV.each do |toolname|
	p toolname
	tool.install toolname
end
