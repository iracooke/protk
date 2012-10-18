#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# A wrapper for PeptideProphet
#
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

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

require 'constants'
require 'command_runner'
require 'prophet_tool'

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
prophet_tool=ProphetTool.new({:glyco=>true,:explicit_output=>true,:maldi=>true})
prophet_tool.option_parser.banner = "Run PeptideProphet on a set of pep.xml input files.\n\nUsage: peptide_prophet.rb [options] file1.pep.xml file2.pep.xml ..."
prophet_tool.options.output_suffix="_pproph"

prophet_tool.options.useicat = false
prophet_tool.option_parser.on( '--useicat',"Use icat information" ) do 
  prophet_tool.options.useicat = true
end

prophet_tool.options.nouseicat = false
prophet_tool.option_parser.on( '--no-useicat',"Do not use icat information" ) do 
  prophet_tool.options.nouseicat = true
end

prophet_tool.options.phospho = false
prophet_tool.option_parser.on( '--phospho',"Use phospho information" ) do 
  prophet_tool.options.phospho = true
end

prophet_tool.options.usepi = false
prophet_tool.option_parser.on( '--usepi',"Use pI information" ) do 
  prophet_tool.options.usepi = true
end

prophet_tool.options.usert = false
prophet_tool.option_parser.on( '--usert',"Use hydrophobicity / RT information" ) do 
  prophet_tool.options.usert = true
end

prophet_tool.options.accurate_mass = false
prophet_tool.option_parser.on( '--accurate-mass',"Use accurate mass binning" ) do 
  prophet_tool.options.accurate_mass = true
end

prophet_tool.options.no_ntt = false
prophet_tool.option_parser.on( '--no-ntt',"Don't use NTT model" ) do 
  prophet_tool.options.no_ntt = true
end

prophet_tool.options.no_nmc = false
prophet_tool.option_parser.on( '--no-nmc',"Don't use NMC model" ) do 
  prophet_tool.options.no_nmc = true
end

prophet_tool.options.usegamma = false
prophet_tool.option_parser.on( '--usegamma',"Use Gamma distribution to model the negatives" ) do 
  prophet_tool.options.usegamma = true
end

prophet_tool.options.use_only_expect = false
prophet_tool.option_parser.on( '--use-only-expect',"Only use Expect Score as the discriminant" ) do 
  prophet_tool.options.use_only_expect = true
end

prophet_tool.options.force_fit = false
prophet_tool.option_parser.on( '--force-fit',"Force fitting of mixture model and bypass checks" ) do 
  prophet_tool.options.force_fit = true
end

prophet_tool.options.allow_alt_instruments=false
prophet_tool.option_parser.on( '--allow-alt-instruments',"Warning instead of exit with error if instrument types between runs is different" ) do 
  prophet_tool.options.allow_alt_instruments = true
end

prophet_tool.options.one_ata_time = false
prophet_tool.option_parser.on( '-F', '--one-ata-time', 'Create a separate pproph output file for each analysis' ) do 
  prophet_tool.options.one_ata_time = true
end

prophet_tool.options.decoy_prefix="decoy"
prophet_tool.option_parser.on( '--decoy-prefix', 'Prefix for decoy sequences') do |prefix|
  prophet_tool.options.decoy_prefix = prefix
end  


prophet_tool.option_parser.parse!

throw "When --output and -F options are set only one file at a time can be run" if  ( ARGV.length> 1 ) && ( prophet_tool.explicit_output!=nil ) && (prophet_tool.one_ata_time!=nil)

# Obtain a global environment object
genv=Constants.new


# Interrogate all the input files to obtain the database and search engine from them
#
genv.log("Determining search engine and database used to create input files ...",:info)
file_info={}
ARGV.each {|file_name| 
  name=file_name.chomp
  
  engine=prophet_tool.extract_engine(name)
  db_path=prophet_tool.extract_db(name)
  
  
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

  retname=  "#{prophet_tool.input_base_path(info[0],".pep.xml")}.pep.xml"
  if ( info[0]=~/\.dat$/)
    retname=info[0]
  end
      
  retname

end

def generate_command(genv,prophet_tool,inputs,output,database,engine)
  
  cmd="#{genv.tpp_bin}/xinteract -N#{output}  -l7 -eT -D#{database} "

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
  end
  
  if prophet_tool.nouseicat
    cmd << " -Of"
  end
  
  if prophet_tool.maldi
    cmd << " -I2 -T3 -I4 -I5 -I6 -I7 "
  end

  if engine=="omssa" || engine=="phenyx"
    cmd << "-Op -P -d#{prophet_tool.decoy_prefix} "
  else
    cmd << "-d#{prophet_tool.decoy_prefix} "
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
    jobscript_path="#{output_path}.pbs.sh"
    job_params={:jobid=>engine, :vmem=>"900mb", :queue => "lowmem"}
    code=prophet_tool.run(cmd,genv,job_params,jobscript_path)
    throw "Command failed with exit code #{code}" unless code==0
  end
end


cmd=""
if ( prophet_tool.one_ata_time )
  inputs.each { |input|
    
    output_file_name="#{prophet_tool.output_prefix}#{input}_#{engine}_interact#{prophet_tool.output_suffix}.pep.xml"
    
    cmd=generate_command(genv,prophet_tool,input,output_file_name,database,engine)

    run_peptide_prophet(genv,prophet_tool,cmd,output_file_base_name,engine)
    
        
  }
else  
  if (prophet_tool.explicit_output==nil)
    output_file_name="#{prophet_tool.output_prefix}#{engine}_interact#{prophet_tool.output_suffix}.pep.xml"
  else

    output_file_name=prophet_tool.explicit_output

  end
  cmd=generate_command(genv,prophet_tool,inputs,output_file_name,database,engine)

  run_peptide_prophet(genv,prophet_tool,cmd,output_file_name,engine)
    
end


