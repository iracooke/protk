#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 30/4/2015
#
# A wrapper for the SpectraST create command
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?
input_stager = nil

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
spectrast_tool=Tool.new([])
spectrast_tool.option_parser.banner = "Create a spectral library from pep.xml input files.\n\nUsage: spectrast_create.rb [options] file1.pep.xml file2.pep.xml ..."

exit unless spectrast_tool.check_options(true)

