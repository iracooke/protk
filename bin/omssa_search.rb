#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the OMSSA search engine
#
$VERBOSE=nil

require 'protk/constants'
require 'protk/command_runner'
require 'protk/search_tool'
require 'protk/galaxy_util'

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new([
  :database,
  :explicit_output,
  :over_write,
  :enzyme,
  :modifications,
  :methionine_oxidation,
  :carbamidomethyl,
  :glyco,
  :instrument,
  :mass_tolerance_units,
  :mass_tolerance,
  :missed_cleavages,
  :precursor_search_type,
  :respect_precursor_charges,
  :num_peaks_for_multi_isotope_search,
  :searched_ions,
  :threads
  ])


search_tool.option_parser.banner = "Run an OMSSA msms search on a set of mgf input files.\n\nUsage: omssa_search.rb [options] file1.mgf file2.mgf ..."

search_tool.add_boolean_option(:add_retention_times,true,['-R', '--no-add-retention-times', 'Don\'t post process the output to add retention times'])
search_tool.add_value_option(:max_hit_expect,1,['--max-hit-expect exp', 'Expect values less than this are considered to be hits'])
search_tool.add_value_option(:intensity_cut_off,0.0005,['--intensity-cut-off co', 'Peak intensity cut-off as a fraction of maximum peak intensity'])
search_tool.add_value_option(:galaxy_index_dir,nil,['--galaxy-index-dir dir', 'Specify galaxy index directory, will search for mods file there.'])
search_tool.add_value_option(:omx_output,nil,['--omx-output path', 'Specify path for additional OMX output (optional).'])
search_tool.add_value_option(:logfile,nil,['--logfile path','Send OMSSA stdout to a logfile'])

exit unless search_tool.check_options(true)

# Environment with global constants
#
genv=Constants.new

# Set search engine specific parameters on the SearchTool object
#
repair_script_bin="#{File.dirname(__FILE__)}/repair_run_summary.rb"

make_blastdb_cmd=""
@output_suffix="_omssa"

db_info = search_tool.database_info

# Index the DB if needed
#
unless File.exists?("#{db_info.path}.phr")
  make_blastdb_cmd << "makeblastdb -dbtype prot -parse_seqids -in #{db_info.path}; "
end

throw "When --output is set only one file at a time can be run" if  ( ARGV.length> 1 ) && ( search_tool.explicit_output!=nil ) 

# Run the search engine on each input file
#
ARGV.each do |filename|

  if ( search_tool.explicit_output!=nil)
    output_path=search_tool.explicit_output
  else
    output_path=Tool.default_output_path(filename,".pep.xml",search_tool.output_prefix,@output_suffix)
  end
  
  input_path=filename.chomp


  # Only proceed if the output file is not present or we have opted to over-write it
  #
  if ( search_tool.over_write || !Pathname.new(output_path).exist? )
  
    # The basic command
    #
    cmd = "#{make_blastdb_cmd} omssacl -nt #{search_tool.threads} -d #{db_info.path} -fm #{input_path} -op #{output_path} -w"

    #Missed cleavages
    #
    cmd << " -v #{search_tool.missed_cleavages}"

    if ( search_tool.omx_output )
      cmd << " -ox #{search_tool.omx_output} "
    end


    # Precursor tolerance
    #
    if ( search_tool.precursor_tolu=="ppm")
      cmd << " -teppm"
    end
    cmd << " -te #{search_tool.precursor_tol}"
    
    # Fragment ion tolerance
    #
    cmd << " -to #{search_tool.fragment_tol}" #Always in Da
    
    # Set the search type (monoisotopic vs average masses) and whether to use strict monoisotopic masses
    #
    if ( search_tool.precursor_search_type=="monoisotopic")
      if ( search_tool.strict_monoisotopic_mass )
        cmd << " -tem 0"
      else
        cmd << " -tem 4 -ti #{search_tool.num_peaks_for_multi_isotope_search}"        
      end
    else
      cmd << " -tem 1"
    end
    
    # Enzyme
    #
    if ( search_tool.enzyme!="Trypsin")
      cmd << " -e #{search_tool.enzyme}"
    end

    # Variable Modifications
    #
    if ( search_tool.var_mods  && !(search_tool.var_mods =~/None/)) # Checking for none is to cope with galaxy input
      var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }
    end

    var_mods=[] unless var_mods
    var_mods << "119" if search_tool.glyco
    var_mods << "1" if search_tool.methionine_oxidation

    cmd << " -mv #{var_mods.join(",")}" if var_mods.length > 0


    if ( search_tool.fix_mods  && !(search_tool.fix_mods=~/None/))
      fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }
    end
    fix_mods=[] unless fix_mods
    fix_mods << ["3"] if search_tool.carbamidomethyl

    cmd << " -mf #{fix_mods.join(",")}" if fix_mods.length > 0
    
    if ( search_tool.searched_ions !="" && !(search_tool.searched_ions=~/None/))
      searched_ions=search_tool.searched_ions.split(",").collect{ |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }.join(",")
      if ( searched_ions!="")
        cmd << " -i #{searched_ions}"
      end
      
    end
    
    # Infer precursor charges or respect charges in input file
    #
    if ( search_tool.respect_precursor_charges )
      cmd << " -zcc 1"
    end
    
    
    # Max expect
    #
    cmd << " -he #{search_tool.max_hit_expect}"
    
    # Intensity cut-off
    cmd << " -ci #{search_tool.intensity_cut_off}"
    
    # Send output to logfile. OMSSA Logging does not play well with Ruby Open4
    cmd << " -logfile #{search_tool.logfile}" if search_tool.logfile

    # Up to here we've formulated the omssa command. The rest is cleanup
    p "Running:#{cmd}"
    
    
    # Correct the pepXML file 
    #
   cmd << "; #{repair_script_bin} -N #{input_path} -R mgf #{output_path} --omssa-itol #{search_tool.fragment_tol}"
    
    # Run the search
    #
    search_tool.run(cmd,genv)


  else
    genv.log("Skipping search on existing file #{output_path}",:warn)       
  end

  # Reset this.  We only want to index the database at most once
  #
  make_blastdb_cmd=""

end
