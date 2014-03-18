#!/usr/bin/env ruby
#
# This file is part of MSLIMS
# Created by Ira Cooke 12/4/2010
#
# Convert mascot dat files to pepxml. A wrapper for Mascot2XML
#


require 'protk/constants'
require 'protk/search_tool'
require 'protk/mascot_util'

# Environment with global constants
#
genv=Constants.new

tool=SearchTool.new([:database,:explicit_output,:over_write,:enzyme])
tool.option_parser.banner = "Convert mascot dat files to pep.xml files.\n\nUsage: mascot_to_pepxml.rb [options] file1.dat file2.dat ... "

tool.options.enzyme="trypsin"

tool.options.shortid=false
tool.option_parser.on( '--shortid', 'Use short protein id as per Mascot result (default uses full protein ids in fasta file)' ) do  
    tool.options.shortid=true
end

tool.option_parser.parse!

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

current_db=""

case 
when Pathname.new(tool.database).exist? # It's an explicitly named db
  current_db=Pathname.new(tool.database).realpath.to_s
else
  current_db=tool.current_database :fasta
end



ARGV.each do |file_name| 
  name=file_name.chomp

  this_dir=Pathname.new(name).dirname.realpath

  if ( tool.explicit_output==nil )
    new_basename="#{this_dir}/#{MascotUtil.input_basename(name)}_mascot2xml"      
    cmd="cp #{name} #{new_basename}.dat"
    cmd << "; #{genv.mascot2xml} #{new_basename}.dat -D#{current_db} -E#{tool.enzyme}"
    
    cmd << " -shortid" if tool.shortid

  else  #Mascot2XML doesn't support explicitly named output files so we move the file to an appropriate output filename after finishing
    new_basename="#{this_dir}/#{MascotUtil.input_basename(name)}_mascot2xml"
    cmd="cp #{name} #{new_basename}.dat"
    cmd << "; Mascot2XML #{new_basename}.dat -D#{current_db} -E#{tool.enzyme}"
    cmd << " -shortid" if tool.shortid
    cmd << "; mv #{new_basename}.pep.xml #{tool.explicit_output}; rm #{new_basename}.dat"
    repair_script="#{File.dirname(__FILE__)}/repair_run_summary.rb"     
    cmd << "; #{repair_script} #{tool.explicit_output}"
  end
    
  code = tool.run(cmd,genv,nil,nil)
  throw "Command #{cmd} failed with exit code #{code}" unless code==0
end