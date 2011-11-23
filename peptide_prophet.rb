#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Runs the PeptideProphet tool on a set of pep.xml files
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
    echo "Unable to find a 'ruby' interpretter!"   >&2
    exit 1
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
prophet_tool.option_parser.banner = "Run PeptideProphet on a set of pep.xml input files.\n\nUsage: peptide_prophet.rb [options] file1.pep.xml file2.pep.xml ..."
prophet_tool.options.output_suffix="_pproph"

prophet_tool.options.one_ata_time = false
prophet_tool.option_parser.on( '-F', '--one-ata-time', 'Create a separate pproph output file for each analysis' ) do 
  prophet_tool.options.one_ata_time = true
end

prophet_tool.options.database = "SPHuman"
prophet_tool.option_parser.on( '-D', '--database db', 'The Database used in the search (required for phenyx results only)' ) do |db|
  prophet_tool.options.database = db
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
  
  if prophet_tool.maldi
    cmd << " -I2 -T3 -I4 -I5 -I6 -I7 "
  end

  if engine=="omssa" || engine=="phenyx"
    cmd << "-Op -P -ddecoy "
  else
    cmd << "-ddecoy "
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
    #    output_file_name=Pathname.new(prophet_tool.explicit_output).basename

    output_file_name=prophet_tool.explicit_output

    # Check for interact- as prefix and remove it
#    throw "Explicitly named outputs must begin with interact_" unless (info[1][:engine]==engine) && (info[1][:database])
  end
  cmd=generate_command(genv,prophet_tool,inputs,output_file_name,database,engine)

  run_peptide_prophet(genv,prophet_tool,cmd,output_file_name,engine)
    
end


