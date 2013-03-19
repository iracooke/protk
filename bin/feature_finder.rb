#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 21/3/2012
#
# A wrapper for the OpenMS FeatureFinder tools (FeatureFinderCentroided and FeatureFinderIsotopeWavelet)

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/openms_defaults'
require 'libxml'

include LibXML

tool=Tool.new({:explicit_output=>true, :background=>true,:over_write=>true,:prefix_suffix=>true})
tool.option_parser.banner = "Find molecular features on a set of input files.\n\nUsage: feature_finder.rb [options] file1.mzML file2.mzML ..."

tool.options.intensity_type = "ref"
tool.option_parser.on( '--intensity-type type',"method used to calculate intensities (ref,trans,corrected). Default = ref. See OpenMS documentation for details" ) do |type|
  tool.options.intensity_type = type
end

tool.options.intensity_threshold = "3"
tool.option_parser.on( '--intensity-threshold thresh',"discard features below this intensity (Default=3). Set to -1 to retain all detected features" ) do |thresh|
  tool.options.intensity_threshold = thresh
end


tool.option_parser.parse!

# Obtain a global environment object
genv=Constants.new

def run_ff(genv,tool,cmd,output_path,jobid)
  if ( !tool.over_write && Pathname.new(output_path).exist? )
    genv.log("Skipping analysis on existing file #{output_path}",:warn)   
  else
    jobscript_path="#{output_path}.pbs.sh"
    job_params={:jobid=>jobid, :vmem=>"14Gb", :queue => "sixteen"}
    code=tool.run(cmd,genv,job_params,jobscript_path)
    throw "Command failed with exit code #{code}" unless code==0
  end
end

def generate_ini(tool,out_path)
  base_ini_file=OpenMSDefaults.new.featurefinderisotopewavelet
  parser = XML::Parser.file(base_ini_file)
  doc = parser.parse
  intensity_threshold_node = doc.find('//ITEM[@name="intensity_threshold"]')[0]
  intensity_type_node = doc.find('//ITEM[@name="intensity_type"]')[0]
  intensity_threshold_node['value']=tool.intensity_threshold
  intensity_type_node['value']=tool.intensity_type
  doc.save(out_path)
end

throw "Cannot use explicit output in combination with multiple input files" if ( tool.explicit_output && ARGV.length>1)

ini_file="#{Pathname.new(ARGV[0]).dirname.realpath.to_s}/feature_finder.ini"

generate_ini(tool,ini_file)

ARGV.each do |filen|
  input_file=filen.chomp
  throw "Input must be an mzML file" unless input_file=~/\.mzML$/

  input_basename=input_file.gsub(/\.mzML$/,'')  
  output_dir=Pathname.new(input_basename).dirname.realpath.to_s
  output_base=Pathname.new(input_basename).basename.to_s
  output_file = "#{output_dir}/#{tool.output_prefix}#{output_base}#{tool.output_suffix}.featureXML"

  if ( tool.over_write || !Pathname.new(output_file).exist? )
    output_base_filename=Pathname.new(output_file).basename.to_s
    cmd=""
    cmd<<"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{genv.openms_root}/lib;
#{genv.featurefinderisotopewavelet} -in #{Pathname.new(input_file).realpath.to_s} -out #{output_dir}/#{output_base_filename} -ini #{ini_file}"
  
    run_ff(genv,tool,cmd,output_file,tool.jobid_from_filename(input_basename))
  
  else
    genv.log("Skipping search on existing file #{output_file}",:warn)    
  end
end
