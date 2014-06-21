#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 17/12/2010
#
# Runs an MS/MS search using the X!Tandem search engine
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tandem_search_tool'
require 'libxml'

include LibXML

# Environment with global constants
#
genv=Constants.new
search_tool=TandemSearchTool.new()

exit unless search_tool.check_options(true)

# Our environment should be setup so that tandem or tandem.exe is on the path
#
tandem_bin=%x[which tandem].chomp
tandem_bin=%x[which tandem.exe].chomp unless tandem_bin && tandem_bin.length>0

@output_suffix="_tandem"

# Run the search engine on each input file
#
ARGV.each do |filename|

  throw "Input file #{filename} does not exist" unless File.exist?(filename)

  input_path=Pathname.new(filename.chomp).expand_path.to_s
  output_path=Tool.default_output_path(input_path,".tandem",search_tool.output_prefix,@output_suffix)


  if ( search_tool.explicit_output )
    final_output_path=search_tool.explicit_output
  else
    final_output_path=output_path
  end
  

  output_exists=Pathname.new(final_output_path).exist?

  puts final_output_path
  if Pathname.new(final_output_path).absolute?
    output_base_path=Pathname.new(final_output_path).dirname.to_s
  else
    output_base_path="#{Dir.pwd}/#{Pathname.new(final_output_path).dirname.to_s}"
  end
  puts output_base_path

  protein_db_info=search_tool.database_info

  taxo_path="#{final_output_path}.taxonomy.xml"
  taxo_doc = search_tool.taxonomy_doc(protein_db_info)
  taxo_doc.save(taxo_path)

  params_path="#{final_output_path}.params"
  params_doc = search_tool.params_doc(protein_db_info,taxo_path,input_path,final_output_path)
  params_doc.save(params_path)

  # Only proceed if the output file is not present or we have opted to over-write it
  #
  if ( search_tool.over_write || !output_exists )

    # The basic command
    #
    cmd= "#{tandem_bin} #{params_path}"

    # Add a cleanup command unless the user wants to keep params files
    #
    unless search_tool.keep_params_files 
      cmd << "; rm #{params_path}; rm #{taxo_path}"
    end
 
    # Run the search
    #
    code = search_tool.run(cmd,genv)
    throw "Command failed with exit code #{code}" unless code==0
  else
    genv.log("Skipping search on existing file #{output_path}",:warn)        
  end

end
