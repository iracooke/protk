#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Corrects retention times in omssa output
#

$VERBOSE=nil

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/omssa_util'

# Environment with global constants
#
genv=Constants.new

tool=Tool.new([:over_write])
tool.option_parser.banner = "Correct retention times on a pepxml file produced by omssa using information from an mgf file.\n\nUsage: correct_omssa_retention_times.rb [options] file1.pep.xml file2.mgf"
tool.option_parser.parse!


OMSSAUtil.add_retention_times(ARGV[1],ARGV[0],tool.over_write,true)


