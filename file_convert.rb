#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Wrapper for msconvert
#

#!/bin/sh
. `dirname \`readlink -f $0\``/protk_run.sh
#! ruby
#

require 'constants'
require 'command_runner'
require 'tool'
require 'tempfile'
require 'libxml'

include LibXML


# Read the input file and search for an instance of the charge state cvParam inside a precursor tag. Return true if one is found. False otherwise
#
def has_charge_information(input_filename)
  #<precursorList count="1">
  #        <precursor spectrumRef="controllerType=0 controllerNumber=1 scan=59">
  #          <isolationWindow>
  #            <cvParam cvRef="MS" accession="MS:1000827" name="isolation window target m/z" value="939.43" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>
  #            <cvParam cvRef="MS" accession="MS:1000828" name="isolation window lower offset" value="2.0" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>
  #            <cvParam cvRef="MS" accession="MS:1000829" name="isolation window upper offset" value="2.0" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>
  #          </isolationWindow>
  #          <selectedIonList count="1">
  #            <selectedIon>
  #              <cvParam cvRef="MS" accession="MS:1000744" name="selected ion m/z" value="939.432189941406" unitCvRef="MS" unitAccession="MS:1000040" unitName="m/z"/>
  #              <cvParam cvRef="MS" accession="MS:1000041" name="charge state" value="2"/>
  #              <cvParam cvRef="MS" accession="MS:1000042" name="peak intensity" value="1321.692016601563" unitCvRef="MS" unitAccession="MS:1000131" unitName="number of counts"/>
  #            </selectedIon>
  #          </selectedIonList>
  
  reader=XML::Reader.file(input_filename)  
  
  while(reader.read)
    
    if ( reader.local_name=="precursor")
      
      subdoc=reader.read_inner_xml
      
      if ( subdoc =~ /MS:1000041/ )
        return true
      end
      
    end
    
  end
  
  return false
  
end



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

#convert_tool.options.missing_charge_state="false"
#convert_tool.option_parser.on( '-C', '--missing-charges', 'No attempt will be made to write charge states. Leads to better looking spectrum names' ) do |fmt| 
#  convert_tool.options.output_format=fmt
#end
#end



convert_tool.option_parser.parse!



# Environment with global constants
#
genv=Constants.new

filename=ARGV[0]


input_ext=Pathname.new(filename).extname
input_relative_filename=Pathname.new(filename).basename.to_s

base_output_dir=Pathname.new(filename).dirname.realpath.to_s #Default output dir is input dir

output_basename=input_relative_filename.gsub(/#{input_ext}$/,"").to_s

if ( convert_tool.explicit_output )
  output_filepath=Pathname.new(convert_tool.explicit_output)
  base_output_dir=output_filepath.dirname.to_s

  if ( convert_tool.explicit_output=~/^\//) # It's an absolute path so use absolute path as output dir
    # Convert base_output_dir to realpath
    #
    base_output_dir=Pathname.new(base_output_dir).realpath.to_s
  end

  output_filename=output_filepath.basename.to_s
  
end

# Create a uniquely named directory to hold the output. This is the only way to know the output of msconvert 
#
output_dir="#{base_output_dir}/#{Pathname.new(Tempfile.new("file_convert").path).basename.to_s}"
Dir.mkdir(output_dir)


throw "Input format is the same as output format" if ( input_ext==".#{convert_tool.output_format}" )
  
genv.log("Converting #{filename} to #{convert_tool.output_format}",:info)
runner=CommandRunner.new(genv)
basedir=Pathname.new(filename).dirname.to_s #Where we run the tool

if ( convert_tool.maldi )
  #For MALDI we know the charge is 1 so set it explicitly. Sometimes it is missing from the data
  runner.run_local("cd #{basedir}; #{genv.tpp_bin}/msconvert #{input_relative_filename} --filter \"titleMaker <RunId>.<ScanNumber>.<ScanNumber>.1\" --#{convert_tool.output_format} -o #{output_dir}")
else
  if ( has_charge_information(filename) )
    runner.run_local("cd #{basedir}; #{genv.tpp_bin}/msconvert #{input_relative_filename} --filter \"titleMaker <RunId>.<ScanNumber>.<ScanNumber>.<ChargeState>\" --#{convert_tool.output_format} -o #{output_dir}")
  else
    # If input file is missing charges the best we can do is just assign charge=1. Search engines can choose to ignore this value anyway.
    #    
    runner.run_local("cd #{basedir}; #{genv.tpp_bin}/msconvert #{input_relative_filename} --filter \"titleMaker <RunId>.<ScanNumber>.<ScanNumber>.1\" --#{convert_tool.output_format} -o #{output_dir}")
  end
end

# Find out what the output name was
#
tmp_output_filename=""
Dir.foreach(output_dir) { |entry_name| 
  if ( entry_name=~/^\.$/ || entry_name=~/^\.\.$/ )
  else
    tmp_output_filename=entry_name
  end
}

# Cleanup after converting
cmd = "cd #{output_dir};pwd; mv #{tmp_output_filename}  #{base_output_dir}/#{output_filename}; cd ../; pwd;rm -r #{output_dir}"

code =runner.run_local(cmd)

throw "Command failed with exit code #{code}" unless code==0

throw "Failed to create output file #{base_output_dir}/#{output_filename}" unless ( FileTest.exists?("#{base_output_dir}/#{output_filename}") )
