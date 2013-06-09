#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 17/1/2011
#
# Runs the Protein Prophet tool on a set of pep.xml files. Accepts input from peptide_prophet or interprophet.
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/prophet_tool'
require 'protk/galaxy_stager'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?

if for_galaxy
  # Stage files for galaxy
  original_input_file = ARGV[0]
  original_input_path = Pathname.new("#{original_input_file}")
  input_stager = GalaxyStager.new("#{original_input_file}", :extension => '.pep.xml')
  ARGV.push("-o")
  ARGV.push("protein_prophet_results.prot.xml")  
end

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
prophet_tool=ProphetTool.new([:glyco,:explicit_output,:over_write,:prefix_suffix])
prophet_tool.option_parser.banner = "Run ProteinProphet on a set of pep.xml input files.\n\nUsage: protein_prophet.rb [options] file1.pep.xml file2.pep.xml ..."
prophet_tool.options.output_suffix="_protproph"

prophet_tool.options.iproph = false
prophet_tool.option_parser.on( '--iprophet-input',"Inputs are from iProphet" ) do 
  prophet_tool.options.iproph = true
end

prophet_tool.options.nooccam = false
prophet_tool.option_parser.on( '--no-occam',"Do not attempt to derive the simplest protein list explaining observed peptides" ) do 
  prophet_tool.options.nooccam = true
end

prophet_tool.options.groupwts = false
prophet_tool.option_parser.on( '--group-wts',"Check peptide's total weight (rather than actual weight) in the Protein Group against the threshold" ) do 
  prophet_tool.options.groupwts = true
end

prophet_tool.options.normprotlen = false
prophet_tool.option_parser.on( '--norm-protlen',"Normalize NSP using Protein Length" ) do 
  prophet_tool.options.normprotlen = true
end

prophet_tool.options.logprobs = false
prophet_tool.option_parser.on( '--log-prob',"Use the log of probability in the confidence calculations" ) do 
  prophet_tool.options.logprobs = true
end

prophet_tool.options.confem = false
prophet_tool.option_parser.on( '--confem',"Use the EM to compute probability given the confidence" ) do 
  prophet_tool.options.confem = true
end

prophet_tool.options.allpeps = false
prophet_tool.option_parser.on( '--allpeps',"Consider all possible peptides in the database in the confidence model" ) do 
  prophet_tool.options.allpeps = true
end

prophet_tool.options.unmapped = false
prophet_tool.option_parser.on( '--unmapped',"Report results for unmapped proteins" ) do 
  prophet_tool.options.unmapped = true
end

prophet_tool.options.instances = false
prophet_tool.option_parser.on( '--instances',"Use Expected Number of Ion Instances to adjust the peptide probabilities prior to NSP adjustment" ) do 
  prophet_tool.options.instances = true
end

prophet_tool.options.delude = false
prophet_tool.option_parser.on( '--delude',"Do NOT use peptide degeneracy information when assessing proteins" ) do 
  prophet_tool.options.delude = true
end

prophet_tool.options.minprob = 0.05
prophet_tool.option_parser.on( '--minprob mp',"Minimum peptide prophet probability for peptides to be considered" ) do |mp|
  prophet_tool.options.minprob = mp
end

prophet_tool.options.minindep = 0
prophet_tool.option_parser.on( '--minindep mp',"Minimum percentage of independent peptides required for a protein" ) do |mp|
  prophet_tool.options.minindep = mp
end

exit unless prophet_tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts prophet_tool.option_parser 
    exit
end


# Obtain a global environment object
genv=Constants.new

if ( prophet_tool.explicit_output==nil )
	output_file="#{prophet_tool.output_prefix}interact#{prophet_tool.output_suffix}.prot.xml"
 else 
	output_file=prophet_tool.explicit_output 
end

p output_file

if ( !Pathname.new(output_file).exist? || prophet_tool.over_write )

  cmd="#{genv.proteinprophet} "

  inputs = ARGV.collect {|file_name| 
    file_name.chomp
  }

  cmd << " #{inputs.join(" ")} #{output_file}"

  if ( prophet_tool.glyco )
    cmd << " GLYC "
  end

  # Run the analysis
  #
  jobscript_path="#{output_file}.pbs.sh"
  job_params={:jobid=>"protproph", :vmem=>"900mb", :queue => "lowmem"}
  genv.log("Running #{cmd}",:info)
  code = prophet_tool.run(cmd,genv,job_params,jobscript_path)
  throw "Command failed with exit code #{code}" unless code==0
else
  genv.log("Protein Prophet output file #{output_file} already exists. Run with -r option to replace",:warn)   
end

if for_galaxy
  # Restore references to peptide prophet xml so downstream tools like 
  # libra can find it.
  input_stager.restore_references("protein_prophet_results.prot.xml")
end




