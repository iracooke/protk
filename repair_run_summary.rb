#
# This file is part of protk
# Created by Ira Cooke 2/12/2011
#
# Repairs the msms_run_summary tag in a pepXML document to contain a specified file and datatype
# This tool should only be used on pepXML files that contain a single msms_run_summary (eg not interprophet results)
#

#!/bin/sh
# -------+---------+---------+-------- + --------+---------+---------+---------+
#     /  This section is a safe way to find the interpretter for ruby,  \
#    |   without caring about the user's setting of PATH.  This reduces  |
#    |   the problems from ruby being installed in different places on   |
#    |   various operating systems.  A much better solution would be to  |
#    |   use  `/usr/bin/env -S-P' , but right now `-S-P' is available    |
#     \  only on FreeBSD 5, 6 & 7.                        Garance/2005  /
# To specify a ruby interpreter set PROTK_RUBY_PATH in your environment. 
# Otherwise standard paths will be searched for ruby
#
if [ -z "$PROTK_RUBY_PATH" ] ; then
  
  for fname in /usr/local/bin /opt/csw/bin /opt/local/bin /usr/bin ; do
    if [ -x "$fname/ruby" ] ; then PROTK_RUBY_PATH="$fname/ruby" ; break; fi
  done
  
  if [ -z "$PROTK_RUBY_PATH" ] ; then
    echo "Unable to find a 'ruby' interpretter!"   >&2
    exit 1
  fi
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#


$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")


require 'constants'
require 'command_runner'
require 'libxml'
require 'tool'

include LibXML

# Environment with global constants
#
genv=Constants.new


# Setup specific command-line options for this tool. Other options are inherited from Tool
#
tool=Tool.new()
tool.option_parser.banner = "Repair msms_run_summary tag in a pepXML file.\n\nUsage: repair_run_summary.rb [options] file1.pepXML"

tool.options.new_base_name=nil
tool.option_parser.on( '-N', '--base-name mzmlfile', 'Original MSMS spectrum file used for search' ) do |file| 
  tool.options.new_base_name = file
end

tool.options.raw_data_type=nil
tool.option_parser.on( '-R', '--raw-type type', 'Raw data type used for search' ) do |type| 
  tool.options.raw_data_type = type
end

tool.option_parser.parse!

pepxml_file=ARGV[0]

# Parse options from a parameter file (if provided), or from the default parameter file
#
parser=XML::Parser.file(pepxml_file)
doc=parser.parse

new_base_name=tool.new_base_name
raw_data_type=tool.raw_data_type

genv.log("Repairing #{pepxml_file} to #{new_base_name} format #{raw_data_type}",:info)

if ( new_base_name==nil )
  # Try X!Tandem first 
  # It would be parameter spectrum,path
  #
  spectrum_path = doc.find('//xmlns:msms_run_summary/xmlns:search_summary/xmlns:parameter[@name="spectrum, path"]','xmlns:http://regis-web.systemsbiology.net/pepXML')[0]
  if ( spectrum_path!=nil)
    new_base_name=spectrum_path.attributes['value']
    raw_data_type="mzML" # Always is for X!Tandem
  end
end

if ( new_base_name==nil )
  # Try Mascot 
  # It would be parameter File path
  #
  #<parameter name="FILE" value="dataset_2.dat"/>
  file_path = doc.find('//xmlns:msms_run_summary/xmlns:search_summary/xmlns:parameter[@name="FILE"]','xmlns:http://regis-web.systemsbiology.net/pepXML')[0]
  if ( file_path!=nil)
    
    run_summary=doc.find('//xmlns:msms_run_summary','xmlns:http://regis-web.systemsbiology.net/pepXML')[0]
    old_base_name=run_summary.attributes['base_name']
    base_dir_path=Pathname.new(old_base_name).dirname.to_s
    
    new_base_name="#{base_dir_path}/#{file_path.attributes['value']}"
    raw_data_type="mgf" # Always is for Mascot
  end
  
end

throw "Could not find original spectrum filename in pepXML and none provided" unless new_base_name!=nil


run_summary=doc.find('//xmlns:msms_run_summary','xmlns:http://regis-web.systemsbiology.net/pepXML')
if ( run_summary[0]==nil)
  # Try without namespace (OMSSA)
  run_summary=doc.find('//msms_run_summary')
  raw_data_type="mgf"
  p run_summary[0]
end

throw "No run summary found" unless run_summary[0]!=nil

run_summary[0].attributes['base_name']=new_base_name
run_summary[0].attributes['raw_data']=raw_data_type

doc.save(pepxml_file)
