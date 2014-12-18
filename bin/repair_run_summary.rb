#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 2/12/2011
#
# Repairs the msms_run_summary tag in a pepXML document to contain a specified file and datatype
# This tool should only be used on pepXML files that contain a single msms_run_summary (eg not interprophet results)
#


require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'libxml'

include LibXML

# Environment with global constants
#
genv=Constants.instance


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

tool.options.omssa_ion_tolerance=nil
tool.option_parser.on('--omssa-itol fitol','Add a fragment ion tolerance parameter to the omssa search summary') do |fitol|
  tool.options.omssa_ion_tolerance=fitol
end

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

pepxml_file=ARGV[0]

# Read the input file
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
  
  if ( tool.options.omssa_ion_tolerance !=nil)
    search_summary=doc.find('//search_summary')[0]
    p search_summary
    pmnode=XML::Node.new('parameter')
    pmnode["name"]="to"
    pmnode["value"]=tool.options.omssa_ion_tolerance.to_s
    search_summary << pmnode
    
  end
  
  raw_data_type="mgf"
end

throw "No run summary found" unless run_summary[0]!=nil

run_summary[0].attributes['base_name']=new_base_name
run_summary[0].attributes['raw_data']=raw_data_type


doc.save(pepxml_file)
