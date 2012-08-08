#
# This file is part of MSLIMS
# Created by Ira Cooke 12/4/2010
#
# Convert mascot dat files to pepxml. A wrapper for Mascot2XML
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
require 'search_tool'
require 'mascot_util'

# Environment with global constants
#
genv=Constants.new

tool=SearchTool.new({:database=>true,:explicit_output=>true,:over_write=>true})
tool.option_parser.banner = "Convert mascot dat files to pep.xml files.\n\nUsage: mascot_to_pepxml.rb [options] file1.dat file2.dat ... "
tool.option_parser.parse!


ARGV.each do |file_name| 
  name=file_name.chomp

  this_dir=Pathname.new(name).dirname.realpath

  if ( tool.explicit_output==nil )
    new_basename="#{this_dir}/#{MascotUtil.input_basename(name)}_mascot2xml"      
    cmd="cp #{name} #{new_basename}.dat"
    cmd << "; #{genv.tpp_bin}/Mascot2XML #{new_basename}.dat -D#{tool.current_database :fasta}"
    
  else  #Mascot2XML doesn't support explicitly named output files so we move the file to an appropriate output filename after finishing
    new_basename="#{this_dir}/#{MascotUtil.input_basename(name)}_mascot2xml"
    cmd="cp #{name} #{new_basename}.dat"
    cmd << "; #{genv.tpp_bin}/Mascot2XML #{new_basename}.dat -D#{tool.current_database :fasta}"
    cmd << "; mv #{new_basename}.pep.xml #{tool.explicit_output}; rm #{new_basename}.dat"
    repair_script="#{File.dirname(__FILE__)}/repair_run_summary.rb"     
    cmd << "; #{repair_script} #{tool.explicit_output}"
  end
    
  code = tool.run(cmd,genv,nil,nil)
  throw "Command #{cmd} failed with exit code #{code}" unless code==0
end