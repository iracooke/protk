#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using multiple search engines on multiple files in parallel
# Merges results using interprophet to produce a single output file
#
# This tool assumes that datasets are from an ESI-QUAD-TOF instrument
#
require 'protk/constants'
require 'protk/command_runner'
require 'protk/search_tool'
require 'protk/big_search_tool'
require 'rest_client'
require 'rake'

# Environment with global constants
#
genv=Constants.new

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new({:msms_search=>true,:background=>false,:database=>true,:over_write=>true,:glyco=>true,:explicit_output=>true})
search_tool.jobid_prefix="b"

search_tool.option_parser.banner = "Run a multi-search engine search on a set of input files.\n\nUsage: big_search.rb [options] file1.mzML file2.mzML ..."
search_tool.options.output_suffix="_multisearch"


search_tool.options.ncpu=1
search_tool.option_parser.on( '-N', '--ncpu n', 'Split tasks into n separate processes if possible' ) do |n| 
  search_tool.options.ncpu=n
end

search_tool.option_parser.parse!

bgsrch = BigSearchTool.new


p bgsrch.run ["hi", "howdy"]