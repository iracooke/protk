#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# A wrapper for PeptideProphet
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/prophet_tool'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?
input_stager = nil

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
prophet_tool=ProphetTool.new([
  :glyco,
  :explicit_output,
  :over_write,
  :maldi,
  :prefix,
  :database])
prophet_tool.option_parser.banner = "Run PeptideProphet on a set of pep.xml input files.\n\nUsage: peptide_prophet.rb [options] file1.pep.xml file2.pep.xml ..."
@output_suffix="_pproph"
prophet_tool.options.database=nil

prophet_tool.add_boolean_option(:useicat,false,['--useicat',"Use icat information"])
prophet_tool.add_boolean_option(:phospho,false,['--phospho',"Use phospho information"])
prophet_tool.add_boolean_option(:usepi,false,['--usepi',"Use pI information"])
prophet_tool.add_boolean_option(:usert,false,['--usert',"Use hydrophobicity / RT information"])
prophet_tool.add_boolean_option(:accurate_mass,false,['--accurate-mass',"Use accurate mass binning"])
prophet_tool.add_boolean_option(:no_ntt,false,['--no-ntt',"Don't use NTT model"])
prophet_tool.add_boolean_option(:no_nmc,false,['--no-nmc',"Don't use NMC model"])
prophet_tool.add_boolean_option(:usegamma,false,['--usegamma',"Use Gamma distribution to model the negatives"])
prophet_tool.add_boolean_option(:use_only_expect,false,['--use-only-expect',"Only use Expect Score as the discriminant"])
prophet_tool.add_boolean_option(:force_fit,false,['--force-fit',"Force fitting of mixture model and bypass checks"])
prophet_tool.add_boolean_option(:allow_alt_instruments,false,['--allow-alt-instruments',"Warning instead of exit with error if instrument types between runs is different"])
prophet_tool.add_boolean_option(:one_ata_time,false,['-F', '--one-ata-time', 'Create a separate pproph output file for each analysis'])
prophet_tool.add_value_option(:decoy_prefix,"decoy",['--decoy-prefix prefix', 'Prefix for decoy sequences'])
prophet_tool.add_boolean_option(:no_decoys,false,['--no-decoy', 'Don\'t use decoy sequences to pin down the negative distribution'])
prophet_tool.add_value_option(:experiment_label,nil,['--experiment-label label','used to commonly label all spectra belonging to one experiment (required by iProphet)'])

exit unless prophet_tool.check_options(true)

throw "When --output and -F options are set only one file at a time can be run" if  ( ARGV.length> 1 ) && ( prophet_tool.explicit_output!=nil ) && (prophet_tool.one_ata_time!=nil)

# Obtain a global environment object
genv=Constants.new


inputs=ARGV.collect { |file_name| file_name.chomp}
if for_galaxy
  inputs = inputs.collect {|ip| GalaxyUtil.stage_pepxml(ip) }
end

# Interrogate all the input files to obtain the database and search engine from them
#
genv.log("Determining search engine and database used to create input files ...",:info)
file_info={}
inputs.each {|file_name| 
  name=file_name.chomp
  
  engine=prophet_tool.extract_engine(name)
  if prophet_tool.database
    db_path = prophet_tool.database_info.path
  else
    db_path=prophet_tool.extract_db(name)
    throw "Unable to find database #{db_path} used for searching. Specify database path using -d option" unless File.exist?(db_path)
  end
  
  
  file_info[name]={:engine=>engine , :database=>db_path } 
}

# Check that all searches were performed with the same engine and database
#
#
engine=nil
database=nil
inputs=file_info.collect do |info|
  if ( engine==nil)
    engine=info[1][:engine]
  end
  if ( database==nil)
    database=info[1][:database]
  end
  throw "All files to be analyzed must have been searched with the same database and search engine" unless (info[1][:engine]==engine) && (info[1][:database])

  retname=  info[0]
  # if ( info[0]=~/\.dat$/)
  #   retname=info[0]
  # end
      
  retname

end

def generate_command(genv,prophet_tool,inputs,output,database,engine)
  
  cmd="xinteract -N#{output}  -l7 -eT -D'#{database}' "

  # Do not produce png plots
  cmd << " -Ot "

  if prophet_tool.glyco 
    cmd << " -Og "
  end

  if prophet_tool.phospho 
    cmd << " -OH "
  end

  if prophet_tool.usepi
    cmd << " -OI "
  end
  
  if prophet_tool.usert
    cmd << " -OR "
  end
  
  if prophet_tool.accurate_mass
    cmd << " -OA "
  end

  if prophet_tool.no_ntt
    cmd << " -ON "
  end
  
  if prophet_tool.no_nmc
    cmd << " -OM "
  end
  
  if prophet_tool.usegamma
    cmd << " -OG "
  end
  
  if prophet_tool.use_only_expect
    cmd << " -OE "
  end
  
  if prophet_tool.force_fit
    cmd << " -OF "
  end
  
  if prophet_tool.allow_alt_instruments
    cmd << " -Ow "
  end
  
  if prophet_tool.useicat
    cmd << " -Oi "
  else
    cmd << " -Of"
  end
  
  if prophet_tool.maldi
    cmd << " -I2 -T3 -I4 -I5 -I6 -I7 "
  end

  if prophet_tool.experiment_label!=nil
    cmd << " -E#{prophet_tool.experiment_label} "
  end

  unless prophet_tool.no_decoys

    if engine=="omssa" || engine=="phenyx"
      cmd << " -Op -P -d#{prophet_tool.decoy_prefix} "
    else
      cmd << " -d#{prophet_tool.decoy_prefix} "
    end
  end  
  
  if ( inputs.class==Array)
    cmd << " #{inputs.join(" ")}"  
  else
    cmd << " #{inputs}"
  end 
  
  cmd
end

def run_peptide_prophet(genv,prophet_tool,cmd,output_path,engine)
  if ( !prophet_tool.over_write && Pathname.new(output_path).exist? )
    genv.log("Skipping analysis on existing file #{output_path}",:warn)   
  else
    code=prophet_tool.run(cmd,genv)
    throw "Command failed with exit code #{code}" unless code==0
  end
end


cmd=""
if ( prophet_tool.one_ata_time )
  
  inputs.each do |input|
    output_file_name=Tool.default_output_path(input,".pep.xml",prophet_tool.output_prefix,@output_suffix)
    
    cmd=generate_command(genv,prophet_tool,input,output_file_name,database,engine)
    run_peptide_prophet(genv,prophet_tool,cmd,output_file_name,engine)        
  end

else  

  if (prophet_tool.explicit_output==nil)
    output_file_name=Tool.default_output_path(inputs[0],".pep.xml",prophet_tool.output_prefix,@output_suffix)    
  else
    output_file_name=prophet_tool.explicit_output
  end

  cmd=generate_command(genv,prophet_tool,inputs,output_file_name,database,engine)
  run_peptide_prophet(genv,prophet_tool,cmd,output_file_name,engine)
    
end


