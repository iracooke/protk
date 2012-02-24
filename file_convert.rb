#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Wrapper for msconvert
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
    echo "Unable to find a 'ruby' interpreter!"   >&2
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
require 'tool'


# Setup specific command-line options for this tool. Other options are inherited from Tool
#
convert_tool=Tool.new({:explicit_output=>true,:over_write=>true,:maldi=>true})
convert_tool.option_parser.banner = "Convert files between different formats.\n\nUsage: file_convert.rb [options] input_file output_file"

# Special case (usually tool specific options use capitals). Use lowercase l here to mimick maldi option in the search_tool class
#
convert_tool.options.maldi=false
convert_tool.option_parser.on( '-l', '--maldi', 'Input Files are MALDI Spectra' ) do 
  convert_tool.options.maldi=true
end

convert_tool.options.output_format="mgf"
convert_tool.option_parser.on( '-F', '--format fmt', 'Convert to a specified format' ) do |fmt| 
  convert_tool.options.output_format=fmt
end



convert_tool.option_parser.parse!

# Environment with global constants
#
genv=Constants.new

filename=ARGV[0]
input_ext=Pathname.new(filename).extname

output_path="#{convert_tool.input_base_path(filename.chomp)}.#{convert_tool.output_format}"

if ( convert_tool.explicit_output )
  final_output_path=convert_tool.explicit_output
else
  final_output_path=output_path
end

throw "Input format is the same as output format" if ( input_ext==".#{convert_tool.output_format}" )
  
genv.log("Converting #{filename} to #{convert_tool.output_format}",:info)
runner=CommandRunner.new(genv)
basedir=Pathname.new(filename).dirname.to_s
relative_filename=Pathname.new(filename).basename

if ( convert_tool.maldi )
  #For MALDI we know the charge is 1 so set it explicitly. Sometimes it is missing from the data
  runner.run_local("cd #{basedir}; #{genv.tpp_bin}/msconvert #{relative_filename} --filter \"titleMaker <RunId>.<ScanNumber>.<ScanNumber>.1\" --#{convert_tool.output_format}")
else
  # This will break if input file is missing charges
  runner.run_local("cd #{basedir}; #{genv.tpp_bin}/msconvert #{relative_filename} --filter \"titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState>\" --#{convert_tool.output_format}")
end

# Cleanup after converting
cmd = "cd #{basedir}; mv #{output_path}  #{final_output_path}"

code =runner.run_local(cmd)

throw "Command failed with exit code #{code}" unless code==0

throw "Failed to create output file #{final_output_path}" unless ( FileTest.exists?(final_output_path) )
