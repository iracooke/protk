#
# This file is part of protk
# Created by Ira Cooke 21/3/2012
#
# A wrapper for the OpenMS FeatureFinder tools (FeatureFinderCentroided and FeatureFinderIsotopeWavelet)
#
#
#!/bin/sh
. `dirname \`readlink -f $0\``/protk_run.sh
#! ruby
#

require 'constants'
require 'command_runner'
require 'tool'

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new({:explicit_output=>true, :background=>true,:over_write=>true})
tool.option_parser.banner = "Find molecular features on a set of input files.\n\nUsage: feature_finder.rb [options] file1.mzML file2.mzML ..."

tool.options.profile = false
tool.option_parser.on( '--profile',"Input files are profile data" ) do 
  tool.options.profile = true
end

tool.option_parser.parse!

# Obtain a global environment object
genv=Constants.new

def run_ff(genv,tool,cmd,output_path,jobid)
  if ( !tool.over_write && Pathname.new(output_path).exist? )
    genv.log("Skipping analysis on existing file #{output_path}",:warn)   
  else
    jobscript_path="#{output_path}.pbs.sh"
    job_params={:jobid=>jobid, :vmem=>"12Gb", :queue => "sixteen"}
    code=tool.run(cmd,genv,job_params,jobscript_path)
    throw "Command failed with exit code #{code}" unless code==0
  end
end


throw "Cannot use explicit output in combination with multiple input files" if ( tool.explicit_output && ARGV.length>1)
throw "The profile option is not yet implemented" if ( tool.profile )

ini_file="#{File.dirname(__FILE__)}/params/FeatureFinderCentroided.ini"

ARGV.each do |filen|
  input_file=filen.chomp
  throw "Input must be an mzML file" unless input_file=~/\.mzML$/

  input_basename=input_file.gsub(/\.mzML$/,'')  
  output_filename=tool.explicit_output 
  output_file="#{input_basename}.featureXML" if output_filename==nil
  
  if ( tool.over_write || !Pathname.new(output_file).exist? )
    output_dir=Pathname.new(output_file).dirname.realpath.to_s
    output_base_filename=Pathname.new(output_file).basename.to_s
    cmd=""
    cmd<<"#{genv.openms_bin}/FeatureFinderCentroided -in #{Pathname.new(input_file).realpath.to_s} -out #{output_dir}/#{output_base_filename} -ini #{ini_file}"

    run_ff(genv,tool,cmd,output_file,tool.jobid_from_filename(input_basename))
  
  else
    genv.log("Skipping search on existing file #{output_file}",:warn)    
  end
end
