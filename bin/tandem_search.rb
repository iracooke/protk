#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 17/12/2010
#
# Runs an MS/MS search using the X!Tandem search engine
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/search_tool'
require 'protk/xtandem_defaults'
require 'libxml'

include LibXML

# Environment with global constants
#
genv=Constants.new

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new([:background,:glyco,:database,:explicit_output,:over_write,
:enzyme,:modifications,:mass_tolerance_units,:mass_tolerance,:strict_monoisotopic_mass,
:missed_cleavages,:cleavage_semi,:carbamidomethyl,:methionine_oxidation
  ])
search_tool.jobid_prefix="x"
search_tool.option_parser.banner = "Run an X!Tandem msms search on a set of mzML input files.\n\nUsage: tandem_search.rb [options] file1.mzML file2.mzML ..."
search_tool.options.output_suffix="_tandem"

tandem_defaults=XTandemDefaults.new
search_tool.options.tandem_params=tandem_defaults.path
search_tool.option_parser.on( '-T', '--tandem-params tandem', 'Path to file containing default parameters' ) do |parms| 
  search_tool.options.tandem_params = parms
end

search_tool.options.keep_params_files=false
search_tool.option_parser.on( '-K', '--keep-params-files', 'Keep X!Tandem parameter files' ) do 
  search_tool.options.keep_params_files = true
end

search_tool.options.thresholds_type = 'isb_kscore'
search_tool.option_parser.on( '--thresholds-type thresholds_type', 'Threshold Type (tandem_default, isb_native, isb_kscore, scaffold, system_default)' ) do |thresholds_type|
  # This options sets up various X! Tandem thresholds. 
  #  - system_default: Don't change any defaults just use
  #      the defaults for this TPP install as is.
  #  - tandem_default: These thresholds are found on the 
  #      tandem api page. http://www.thegpm.org/tandem/api/index.html
  #  - isb_native: These are the defaults found in 
  #      isb_default_input_native.xml distributed with TPP 4.6.
  #  - isb_kscore: These are the defaults found in 
  #      isb_default_input_kscore.xml distributed with TPP 4.6.
  #  - scaffold: These are the defaults recommend by Proteome Software
  #      for use with Scaffold.
  search_tool.options.thresholds_type = thresholds_type
end

search_tool.options.algorithm = "native"
search_tool.option_parser.on( '--algorithm algorithm', "Scoring algorithm (kscore or native)" ) do |algorithm|
  search_tool.options.algorithm = algorithm
end

search_tool.options.n_terminal_mod_mass=nil
search_tool.option_parser.on('--n-terminal-mod-mass mass') do |mass|
    search_tool.options.n_terminal_mod_mass = mass
end

search_tool.options.c_terminal_mod_mass=nil
search_tool.option_parser.on('--c-terminal-mod-mass mass') do |mass|
    search_tool.options.c_terminal_mod_mass = mass
end

search_tool.options.cleavage_n_terminal_mod_mass=nil
search_tool.option_parser.on('--cleavage-n-terminal-mod-mass mass') do |mass|
    search_tool.options.cleavage_n_terminal_mod_mass = mass
end

search_tool.options.cleavage_c_terminal_mod_mass=nil
search_tool.option_parser.on('--cleavage-c-terminal-mod-mass mass') do |mass|
    search_tool.options.cleavage_c_terminal_mod_mass = mass
end

# if contrast angle is set we need to insert two parameters into the XML file ("use contrast angle" and "contrast angle")
search_tool.options.contrast_angle=nil
search_tool.option_parser.on('--contrast-angle angle') do |angle|
    search_tool.options.contrast_angle = angle
end

search_tool.options.total_peaks=nil
search_tool.option_parser.on('--total-peaks peaks') do |peaks|
    search_tool.options.total_peaks = peaks
end

# TODO: check default
search_tool.options.use_neutral_loss_window=false
search_tool.option_parser.on('--use-neutral-loss-window') do
    search_tool.options.use_neutral_loss_window = true
end


search_tool.options.threads=1
search_tool.option_parser.on('--threads threads') do |threads|
    search_tool.options.threads = threads
end

exit unless search_tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts search_tool.option_parser 
    exit
end


# Set search engine specific parameters on the SearchTool object
#
# Our environment should be setup so that tandem is on the path
#
tandem_bin=%x[which tandem].chomp

# Run the search engine on each input file
#
ARGV.each do |filename|

  input_path=Pathname.new(filename.chomp).realpath.to_s
  output_path="#{search_tool.output_base_path(input_path)}.tandem"

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

  taxo_path="#{final_output_path}.taxonomy.xml"
  params_path="#{final_output_path}.params"
  
  tandem_defaults.generate_params(params_path,taxo_path,input_path,final_output_path,search_tool,genv)

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

    # In case the user specified background running we need to create a jobscript path
    #
    jobscript_path="#{output_path}.pbs.sh"
 
    # Run the search
    #
    job_params= {:jobid => search_tool.jobid_from_filename(filename)}
    job_params[:queue]="sixteen"
    job_params[:vmem]="12gb"
    code = search_tool.run(cmd,genv,job_params,jobscript_path)
    throw "Command failed with exit code #{code}" unless code==0
  else
    genv.log("Skipping search on existing file #{output_path}",:warn)        
  end

end
