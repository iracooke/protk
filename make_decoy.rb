#
# This file is part of protk
# Created by Ira Cooke 9/3/2012
#
# Create a decoy database based on a set of real protein sequences
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

require 'libxml'
require 'constants'
require 'command_runner'
require 'tool'
require 'bio'

include LibXML

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new({:explicit_output=>true})
tool.option_parser.banner = "Create a decoy database from real protein sequences.\n\nUsage: make_decoy.rb [options] realdb.fasta"

tool.options.db_length=0
tool.option_parser.on('-L len','--db-length len','Number of sequences to generate') do |len|
  tool.options.db_length=len.to_i
end

tool.options.prefix_string="decoy_"
tool.option_parser.on('-P str','--prefix-string str','String to prepend to sequence ids') do |str|
  tool.options.prefix_string=str
end

tool.options.append=false
tool.option_parser.on('-A','--append','Append input sequences to the generated database') do 
  tool.options.append=true
end


tool.option_parser.parse!

input_file=ARGV[0]


db_length=tool.db_length
if ( db_length==0) #If no db length was specified use the number of entries in the input file
  db_length=Bio::FastaFormat.open(input_file).count
  p "Found #{db_length} entries in input file"
end

output_file="decoy_#{input_file}"

output_file = tool.explicit_output if tool.explicit_output!=nil

genv=Constants.new()

cmd = "#{genv.bin}/make_random #{input_file} #{db_length} #{output_file} #{tool.prefix_string}"
cmd << "; cat #{input_file} >> #{output_file}" if ( tool.append ) 
p cmd
# Run the conversion
#
job_params= {:jobid => tool.jobid_from_filename(input_file) }
job_params[:queue]="lowmem"
job_params[:vmem]="900mb"    
tool.run(cmd,genv,job_params)