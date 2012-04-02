#
# This file is part of protk
# Created by Ira Cooke 17/1/2011
#
# Runs the Protein Prophet tool on a set of pep.xml files. Accepts input from peptide_prophet or interprophet.
#
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
    PROTK_RUBY_PATH=`which ruby`
#    echo "Unable to find a 'ruby' interpretter!"   >&2
#    exit 1
  fi
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

require 'constants'
require 'command_runner'
require 'prophet_tool'

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
prophet_tool=ProphetTool.new({:glyco=>true,:explicit_output=>true})
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

prophet_tool.option_parser.parse!


# Obtain a global environment object
genv=Constants.new

if ( prophet_tool.explicit_output==nil )
	output_file="#{prophet_tool.output_prefix}interact#{prophet_tool.output_suffix}.prot.xml"
 else 
	output_file=prophet_tool.explicit_output 
end

p output_file

if ( !Pathname.new(output_file).exist? || prophet_tool.over_write )

  cmd="#{genv.tpp_bin}/ProteinProphet "

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






