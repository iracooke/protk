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

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
prophet_tool=ProphetTool.new([:glyco,:explicit_output,:over_write,:prefix])
prophet_tool.option_parser.banner = "Run ProteinProphet on a set of pep.xml input files.\n\nUsage: protein_prophet.rb [options] file1.pep.xml file2.pep.xml ..."

@output_suffix="_protproph"

prophet_tool.add_boolean_option(:iproph,false,['--iprophet-input',"Inputs are from iProphet"])
prophet_tool.add_boolean_option(:nooccam,false,['--no-occam',"Do not attempt to derive the simplest protein list explaining observed peptides"])
prophet_tool.add_boolean_option(:groupwts,false,['--group-wts',"Check peptide's total weight (rather than actual weight) in the Protein Group against the threshold"])
prophet_tool.add_boolean_option(:normprotlen,false,['--norm-protlen',"Normalize NSP using Protein Length"])
prophet_tool.add_boolean_option(:logprobs,false,['--log-prob',"Use the log of probability in the confidence calculations"])
prophet_tool.add_boolean_option(:confem,false,['--confem',"Use the EM to compute probability given the confidence"])
prophet_tool.add_boolean_option(:allpeps,false,['--allpeps',"Consider all possible peptides in the database in the confidence model"])
prophet_tool.add_boolean_option(:unmapped,false,['--unmapped',"Report results for unmapped proteins"])
prophet_tool.add_boolean_option(:instances,false,['--instances',"Use Expected Number of Ion Instances to adjust the peptide probabilities prior to NSP adjustment"])
prophet_tool.add_boolean_option(:delude,false,['--delude',"Do NOT use peptide degeneracy information when assessing proteins"])
prophet_tool.add_value_option(:minprob,0.05,['--minprob mp',"Minimum peptide prophet probability for peptides to be considered"])
prophet_tool.add_value_option(:minindep,0,['--minindep mp',"Minimum percentage of independent peptides required for a protein"])

exit unless prophet_tool.check_options(true)

# Obtain a global environment object
genv=Constants.instance

input_stagers=[]
inputs=ARGV.collect { |file_name| file_name.chomp}
if for_galaxy
  input_stagers = inputs.collect {|ip| GalaxyUtil.stage_pepxml(ip) }
  inputs=input_stagers.collect { |sg| sg.staged_path }
end


if ( prophet_tool.explicit_output )
  output_file=prophet_tool.explicit_output
else
  output_file=Tool.default_output_path(inputs,".prot.xml",prophet_tool.output_prefix,@output_suffix)
end

genv.log("Checking input files ...",:info)
inputs.each {|file_name| 

  throw "Missing input file #{file_name}" unless File.exist?(file_name)

  file_pepxml = PepXML.new(file_name)

  db_path=file_pepxml.extract_db()
  throw "Unable to find database #{db_path} used for searching. Fix paths in input files first" unless File.exist?(db_path)
}



if ( !Pathname.new(output_file).exist? || prophet_tool.over_write )

  cmd="ProteinProphet "

  cmd << " #{inputs.join(" ")} #{output_file}"

  if ( prophet_tool.iproph )
    cmd << " IPROPHET "
  end

  if ( prophet_tool.nooccam )
    cmd << " NOOCCAM "
  end

  if ( prophet_tool.groupwts )
    cmd << " GROUPWTS "
  end

  if ( prophet_tool.normprotlen )
    cmd << " NORMPROTLEN "
  end

  if ( prophet_tool.logprobs )
    cmd << " LOGPROBS "
  end

  if ( prophet_tool.allpeps )
    cmd << " ALLPEPS "
  end

  if ( prophet_tool.unmapped )
    cmd << " UNMAPPED "
  end

  if ( prophet_tool.glyco )
    cmd << " GLYC "
  end

  if ( prophet_tool.delude )
    cmd << " DELUDE "
  end

  if ( prophet_tool.instances )
    cmd << " INSTANCES "
  end

  cmd << " MINPROB=#{prophet_tool.minprob} "

  cmd << " MININDEP=#{prophet_tool.minindep} "

  # Run the analysis
  #
  code = prophet_tool.run(cmd,genv)
  throw "Command failed with exit code #{code}" unless code==0
else
  genv.log("Protein Prophet output file #{output_file} already exists. Run with -r option to replace",:warn)   
end


if (for_galaxy)
  input_stagers.each do |sg|
    sg.restore_references(output_file)
    sg.restore_references(output_file,{:base_only => true})
  end
end




