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
if ( tool.option_parser.banner=="")
  tool.option_parser.banner = "Post install tasks for protk.\nUsage: protk_setup.rb [options] toolname"
end

tool.option_parser.parse!

# Create install directory if it doesn't already exist
#
env=Constants.new

ARGV.each do |toolname|
  tool.install toolname
end
