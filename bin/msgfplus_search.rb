#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the MSGFPlus search engine
#
$VERBOSE=nil
require 'protk/constants'
require 'protk/command_runner'
require 'protk/search_tool'
require 'protk/galaxy_stager'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy
input_stager = nil

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new({:msms_search=>true,:background=>false,:glyco=>false,:database=>true,:explicit_output=>true,:over_write=>true,:msms_search_detailed_options=>true})
search_tool.option_parser.banner = "Run an MSGFPlus msms search on a set of msms spectrum input files.\n\nUsage: msgfplus_search.rb [options] file1.mzML file2.mzML ..."
search_tool.options.output_suffix="_msgfplus"

search_tool.options.fragment_method=0
search_tool.option_parser.on(  '--fragment-method method', 'Fragment method 0: As written in the spectrum or CID if no info (Default), 1: CID, 2: ETD, 3: HCD, 4: Merge spectra from the same precursor' ) do |method|
  search_tool.options.fragment_method=method
end

search_tool.options.protocol=0
search_tool.option_parser.on(  '--protocol p', '0: NoProtocol (Default), 1: Phosphorylation' ) do |p|
  search_tool.options.protocol=p
end

search_tool.options.min_pep_length=6
search_tool.option_parser.on(  '--min-pep-length p', 'Minimum peptide length to consider, Default: 6' ) do |p|
  search_tool.options.min_pep_length=p
end

search_tool.options.max_pep_length=40
search_tool.option_parser.on(  '--max-pep-length p', 'Maximum peptide length to consider, Default: 40' ) do |p|
  search_tool.options.max_pep_length=p
end

search_tool.options.min_pep_charge=2
search_tool.option_parser.on(  '--min-pep-charge c', 'Minimum precursor charge to consider if charges are not specified in the spectrum file, Default: 2' ) do |c|
  search_tool.options.min_pep_charge=c
end

search_tool.options.max_pep_charge=3
search_tool.option_parser.on(  '--max-pep-charge c', 'Maximum precursor charge to consider if charges are not specified in the spectrum file, Default: 3' ) do |c|
  search_tool.options.max_pep_charge=c
end

search_tool.options.num_reported_matches=1
search_tool.option_parser.on(  '--num-reported-matches n', 'Number of matches per spectrum to be reported, Default: 1' ) do |n|
  search_tool.options.num_reported_matches=n
end

search_tool.options.add_features=false
search_tool.option_parser.on(  '--add-features', 'output additional features' ) do 
  search_tool.options.add_features=true
end

search_tool.options.java_mem="3500M"
search_tool.option_parser.on('--java-mem mem','Java memory limit when running the search (Default 3.5Gb)') do |mem|
  search_tool.options.java_mem=mem
end
  
search_tool.option_parser.parse!

# Environment with global constants
#
genv=Constants.new

# Set search engine specific parameters on the SearchTool object
#
msgf_bin="#{genv.msgfplusjar}"

case 
when Pathname.new(search_tool.database).exist? # It's an explicitly named db
  current_db=Pathname.new(search_tool.database).realpath.to_s
else
  current_db=search_tool.current_database :fasta
end

fragment_tol = search_tool.fragment_tol
precursor_tol = search_tool.precursor_tol


throw "When --output is set only one file at a time can be run" if  ( ARGV.length> 1 ) && ( search_tool.explicit_output!=nil ) 

# Run the search engine on each input file
#
ARGV.each do |filename|

  if ( search_tool.explicit_output!=nil)
    output_path=search_tool.explicit_output
  else
    output_path="#{search_tool.output_base_path(filename.chomp)}.pepXML"
  end


  # (*.mzML, *.mzXML, *.mgf, *.ms2, *.pkl or *_dta.txt)
  # Get the input file extension
  ext = Pathname.new(filename).extname
  input_path="#{search_tool.input_base_path(filename.chomp)}#{ext}"

  mzid_output_path="#{search_tool.input_base_path(filename.chomp)}.mzid"


  if for_galaxy
    original_input_file = input_path
    original_input_path = Pathname.new("#{original_input_file}")
    input_stager = GalaxyStager.new("#{original_input_file}", :extension => '.mzML')
    input_path = input_stager.staged_path
  end



  # Only proceed if the output file is not present or we have opted to over-write it
  #
  if ( search_tool.over_write || !Pathname.new(output_path).exist? )
  
    # The basic command
    #
    cmd= "java -Xmx#{search_tool.java_mem} -jar #{msgf_bin} -d #{current_db} -s #{input_path} -o #{mzid_output_path} "
    #Missed cleavages
    #
    throw "Maximum value for missed cleavages is 2" if ( search_tool.missed_cleavages.to_i > 2)
    cmd << " -ntt #{search_tool.missed_cleavages}"

    # Precursor tolerance
    #
    cmd << " -t #{search_tool.precursor_tol}#{search_tool.precursor_tolu}"
    
    # Instrument type
    cmd << " -inst #{search_tool.instrument}"
    
#    cmd << " -m 4"

    cmd << " -addFeatures 1"

    # Enzyme
    #
  #    if ( search_tool.enzyme!="Trypsin")
  #      cmd << " -e #{search_tool.enzyme}"
  #    end

  mods_file_content = ""

    # Variable Modifications
    #
    if ( search_tool.var_mods !="" && !search_tool.var_mods =~/None/) # Checking for none is to cope with galaxy input
      var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }.join("\n")
      if ( var_mods !="" )
        mods_file_content << "#{var_mods}\n"
      end
    end

  # Fixed modifications
  #
    if ( search_tool.fix_mods !="" && !search_tool.fix_mods=~/None/)
      fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }.join("\n")
      if ( fix_mods !="")
        mods_file_content << "#{fix_mods}"    
      end
    end

    if ( mods_file_content != "")
      mods_path="#{search_tool.input_base_path(filename.chomp)}.msgfplus_mods.txt"
      mods_file=File.open(mods_path,'w+')
      mods_file.write "NumMods=2\n#{mods_file_content}"
      mods_file.close
      cmd << " -mod #{mods_path}"
    end
    
    # As a final part of the command we convert to pepxml
    cmd << "; #{genv.idconvert} #{mzid_output_path} --pepXML -o #{Pathname.new(mzid_output_path).dirname}"

    #Then copy the pepxml to the final output path
    cmd << "; cp #{mzid_output_path.chomp('.mzid')}.pepXML #{output_path}"

    # Up to here we've formulated the command. The rest is cleanup
    p "Running:#{cmd}"
    
    # Run the search
    #
    job_params= {:jobid => search_tool.jobid_from_filename(filename) }
    search_tool.run(cmd,genv,job_params)

    input_stager.replace_references(output_path)

  else
    genv.log("Skipping search on existing file #{output_path}",:warn)       
  end

end