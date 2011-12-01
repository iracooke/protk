#
# This file is part of MSLIMS
# Created by Ira Cooke 12/4/2010
#
# Finds molecular features in profile spectra
#
#!/bin/sh
# -------+---------+---------+-------- + --------+---------+---------+---------+
#     /  This section is a safe way to find the interpretter for ruby,  \
#    |   without caring about the user's setting of PATH.  This reduces  |
#    |   the problems from ruby being installed in different places on   |
#    |   various operating systems.  A much better solution would be to  |
#    |   use  `/usr/bin/env -S-P' , but right now `-S-P' is available    |
#     \  only on FreeBSD 5, 6 & 7.                        Garance/2005  /
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
require 'search_tool'
require 'mascot_util'

# Environment with global constants
#
genv=Constants.new

tool=SearchTool.new({:database=>true,:explicit_output=>true,:over_write=>true})
tool.option_parser.banner = "Convert mascot dat files to appropriately named pep.xml files.\n\nUsage: mascot_to_pepxml.rb [options] file1.dat file2.dat ... "
tool.option_parser.parse!


ARGV.each do |file_name| 
  name=file_name.chomp

  this_dir=Pathname.new(name).dirname.realpath
#  p this_dir

#  p "#{this_dir}/#{name}"
#  p MascotUtil.input_basename("#{this_dir}/#{name}")
#  exit()

  # Rename the mascot dat file
  #
  if ( tool.explicit_output==nil )
    new_basename="#{this_dir}/#{MascotUtil.input_basename(name)}_mascot2xml"      
    cmd="cp #{name} #{new_basename}.dat"
    cmd << "; #{genv.tpp_bin}/Mascot2XML #{new_basename}.dat -D#{tool.current_database :fasta}"
    
  else 
    new_basename="#{this_dir}/#{MascotUtil.input_basename(name)}_mascot2xml"
    cmd="cp #{name} #{new_basename}.dat"
    cmd << "; #{genv.tpp_bin}/Mascot2XML #{new_basename}.dat -D#{tool.current_database :fasta}"
    cmd << "; mv #{new_basename}.pep.xml #{tool.explicit_output}"    
  end

#  p new_basename
#  exit()
  p cmd
    
  code = tool.run(cmd,genv,nil,nil)
  throw "Command failed with exit code #{code}" unless code==0
end