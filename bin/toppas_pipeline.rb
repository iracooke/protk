#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 30/01/13
#
# A wrapper for the OpenMS tool ExecutePipeline. 
# Executes simple toppas pipelines, automatically creating the trf file.

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/openms_defaults'
require 'tempfile'
require 'libxml'

include LibXML

tool=Tool.new({:explicit_output=>false, :background=>true,:over_write=>false})
tool.option_parser.banner = "Execute a toppas pipeline with a single inputs node\n\nUsage: toppas_pipeline.rb [options] input1 input2 ..."

tool.options.outdir = ""
tool.option_parser.on( '--outdir dir',"save outputs to dir" ) do |dir|
  tool.options.outdir = dir
end

tool.options.toppas_file = ""
tool.option_parser.on( '--toppas-file f',"the toppas file to run" ) do |file|
  tool.options.toppas_file = file
end

tool.option_parser.parse!

# Obtain a global environment object
genv=Constants.new

def run_pipeline(genv,tool,cmd,output_path,jobid)
  jobscript_path="#{output_path}.pbs.sh"
  job_params={:jobid=>jobid, :vmem=>"14Gb", :queue => "sixteen"}
  code=tool.run(cmd,genv,job_params,jobscript_path)
  throw "Command failed with exit code #{code}" unless code==0
end

def generate_trf(input_files,out_path)
  p OpenMSDefaults.new.trf_path
  parser=XML::Parser.file(OpenMSDefaults.new.trf_path)
  doc=parser.parse
  itemlist_node=doc.find('/PARAMETERS/NODE/ITEMLIST')[0]

  input_files.each do |f|

    mnode=XML::Node.new('LISTITEM')
    mnode["value"]="file://#{Pathname.new(f).realpath.to_s}"
    
    itemlist_node << mnode
  end
  p out_path
  doc.save(out_path)
end

throw "outdir is a required parameter" if tool.outdir==""
throw "toppas-file is a required parameter" if tool.toppas_file==""
throw "outdir must exist" unless Dir.exist?(tool.outdir)

trf_path = "#{tool.toppas_file}.trf"

generate_trf(ARGV,trf_path)

cmd=""
cmd<<"export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:#{genv.openms_root}/lib;
#{genv.executepipeline} -in #{Pathname.new(tool.toppas_file).realpath.to_s} -out_dir #{Pathname.new(tool.outdir).realpath.to_s} -resource_file #{Pathname.new(trf_path).realpath.to_s}"

run_pipeline(genv,tool,cmd,tool.outdir,tool.jobid_from_filename(tool.toppas_file))

