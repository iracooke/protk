#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the OMSSA search engine
#
#!/bin/sh
if [ -z "$PROTK_RUBY_PATH" ] ; then
  PROTK_RUBY_PATH=`which ruby`
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#

$VERBOSE=nil

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

require 'constants'
require 'command_runner'
require 'tool'
require 'omssa_util'

# Environment with global constants
#
genv=Constants.new

tool=Tool.new 
tool.option_parser.banner = "Correct retention times on a pepxml file produced by omssa using information from an mgf file.\n\nUsage: correct_omssa_retention_times.rb [options] file1.pep.xml file2.mgf"
tool.option_parser.parse!


OMSSAUtil.add_retention_times(ARGV[1],ARGV[0],tool.over_write,true)


