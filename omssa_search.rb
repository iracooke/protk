#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the OMSSA search engine
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

$VERBOSE=nil

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

require 'constants'
require 'command_runner'
require 'search_tool'
require 'galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new({:msms_search=>true,:background=>false,:glyco=>true,:database=>true,:explicit_output=>true,:over_write=>true,:msms_search_detailed_options=>true})
search_tool.option_parser.banner = "Run an OMSSA msms search on a set of mgf input files.\n\nUsage: omssa_search.rb [options] file1.mgf file2.mgf ..."
search_tool.options.output_suffix="_omssa"

search_tool.options.add_retention_times=true
search_tool.option_parser.on( '-R', '--no-add-retention-times', 'Don\'t post process the output to add retention times' ) do 
  search_tool.options.add_retention_times=false
end

search_tool.options.max_hit_expect=1
search_tool.option_parser.on(  '--max-hit-expect exp', 'Expect values less than this are considered to be hits' ) do |exp|
  search_tool.options.max_hit_expect=exp
end

search_tool.options.intensity_cut_off=0.0005
search_tool.option_parser.on(  '--intensity-cut-off co', 'Peak intensity cut-off as a fraction of maximum peak intensity' ) do |co|
  search_tool.options.intensity_cut_off=co
end

search_tool.options.galaxy_index_dir=nil
search_tool.option_parser.on( '--galaxy-index-dir dir', 'Specify galaxy index directory, will search for mods file there.' ) do |dir|
  search_tool.options.galaxy_index_dir=dir
end


search_tool.option_parser.parse!

# Environment with global constants
#
genv=Constants.new

# Set search engine specific parameters on the SearchTool object
#
omssa_bin="#{genv.omssa_bin}/omssacl"
omssa2pepxml_bin="#{genv.omssa_bin}/omssa2pepXML"

rt_correct_bin="#{File.dirname(__FILE__)}/correct_omssa_retention_times.rb"
repair_script_bin="#{File.dirname(__FILE__)}/repair_run_summary.rb"

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
    output_path="#{search_tool.output_base_path(filename.chomp)}.pep.xml"
  end
  
  # We always perform searches on mgf files so 
  #
  input_path="#{search_tool.input_base_path(filename.chomp)}.mgf"
  input_ext=Pathname.new(filename).extname

  if ( input_ext==".dat" )
    # This is a file provided by galaxy so we need to leave the .dat extension
    input_path="#{search_tool.input_base_path(filename.chomp)}.dat"
  end


  # Only proceed if the output file is not present or we have opted to over-write it
  #
  if ( search_tool.over_write || !Pathname.new(output_path).exist? )
  
    # The basic command
    #
    cmd= "#{omssa_bin} -d #{current_db} -fm #{input_path} -op #{output_path} -w"

    #Missed cleavages
    #
    cmd << " -v #{search_tool.missed_cleavages}"

    # If this is for Galaxy and a data directory has been specified
    # look for a common unimod.xml file.
    if for_galaxy
      galaxy_index_dir = search_tool.galaxy_index_dir
      if galaxy_index_dir
        galaxy_unimod = File.join(galaxy_index_dir, "unimod.xml")
        if( !FileTest.exists?(galaxy_unimod) )      
          cmd << " -mx #{galaxy_unimod}"
        end
      end
    end

    # Precursor tolerance
    #
    if ( search_tool.precursor_tolu=="ppm")
      cmd << " -teppm"
    end
    cmd << " -te #{search_tool.precursor_tol}"
    
    # Fragment ion tolerance
    #
    cmd << " -to #{fragment_tol}" #Always in Da
    
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
    if ( search_tool.var_mods !="" && !search_tool.var_mods =~/None/) # Checking for none is to cope with galaxy input
      var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }.join(",")
      if ( var_mods !="" )
        cmd << " -mv #{var_mods}"
      end
    else 
      # Add options related to peptide modifications
      #
      if ( search_tool.glyco )
        cmd << " -mv 119 "
      end
    end

    if ( search_tool.fix_mods !="" && !search_tool.fix_mods=~/None/)
      fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }.join(",")
      if ( fix_mods !="")
        cmd << " -mf #{fix_mods}"    
      end
    else
      if ( search_tool.has_modifications )
        cmd << " -mf "
        if ( search_tool.carbamidomethyl )
          cmd<<"3 "
        end

        if ( search_tool.methionine_oxidation )
          cmd<<"1 "
        end

      end
    end
    
    if ( search_tool.searched_ions !="" && !search_tool.searched_ions=~/None/)
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
    
    # Up to here we've formulated the omssa command. The rest is cleanup
    p "Running:#{cmd}"
    
    # Add retention time corrections
    #
    if (search_tool.options.add_retention_times)
      cmd << "; #{rt_correct_bin} #{output_path} #{input_path} "
    end
    
    # Correct the pepXML file 
    #
    cmd << "; #{repair_script_bin} -N #{input_path} -R mgf #{output_path} --omssa-itol #{search_tool.fragment_tol}"
    genv.log("Running repair script command #{cmd}",:info)
    
    # Run the search
    #
    job_params= {:jobid => search_tool.jobid_from_filename(filename) }
    job_params[:queue]="lowmem"
    job_params[:vmem]="900mb"    
    search_tool.run(cmd,genv,job_params)


  else
    genv.log("Skipping search on existing file #{output_path}",:warn)       
  end

end
