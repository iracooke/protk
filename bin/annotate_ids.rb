#
# This file is part of MSLIMS
# Created by Ira Cooke 21/7/2011
#
# Takes an input file with a list of identified proteins and creates a table with swissprot/uniprot database details in various columns for each protein in the input file.
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
require 'protein_annotator'



# Setup specific command-line options for this tool. Other options are inherited from Tool
#
id_tool=ProphetTool.new({:explicit_output=>true,:over_write=>true})
id_tool.option_parser.banner = "Run ID annotation on a prot.xml input file.\n\nUsage: annotate_ids.rb [options] file1.prot.xml"
id_tool.options.output_prefix="annotated_"


id_tool.options.input_format=nil
id_tool.option_parser.on( '-I', '--input-format format', 'Format of input file' ) do |format| 
  id_tool.options.input_format = format
end

id_tool.option_parser.parse!

# Obtain a global environment object
genv=Constants.new

input_file=ARGV[0]

database_file=id_tool.extract_db(input_file)

output_file=nil

if ( id_tool.explicit_output==nil)
  output_file="#{id_tool.output_prefix}#{input_file}#{id_tool.output_suffix}.xls"
else
  output_file=id_tool.explicit_output
end

converter=ProteinAnnotator.new

begin
  outpath=Pathname.new(output_file)
        
  if ( id_tool.over_write || !outpath.exist? )
    converter.convert(input_file,output_file,id_tool.input_format)
  else
    p "Output file #{output_file} already exists"
  end

rescue Exception
  p "Couldn't convert #{input_file}"
  raise
end
