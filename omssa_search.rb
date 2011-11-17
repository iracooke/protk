#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the OMSSA search engine
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

require 'constants'
require 'command_runner'
require 'search_tool'


# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new({:msms_search=>true,:background=>false,:glyco=>true,:database=>true,:explicit_output=>true,:over_write=>true,:maldi=>true})
search_tool.option_parser.banner = "Run an OMSSA msms search on a set of mgf input files.\n\nUsage: omssa_search.rb [options] file1.mgf file2.mgf ..."
search_tool.options.output_suffix="_omssa"

search_tool.options.add_retention_times=true
search_tool.option_parser.on( '-R', '--no-add-retention-times', 'Post process the output to add retention times' ) do 
  search_tool.options.add_retention_times=false
end

search_tool.options.no_charges=false
search_tool.option_parser.on( '-C', '--no-charges', 'Input Files are Missing Charge Information' ) do 
  search_tool.options.no_charges=true
end



search_tool.option_parser.parse!

# Environment with global constants
#
genv=Constants.new



# Set search engine specific parameters on the SearchTool object
#
omssa_bin="#{genv.omssa_executable}/omssacl"
omssa2pepxml_bin="#{genv.omssa_executable}/omssa2pepXML"
## TODO: Refactor into a separate tool
rt_correct_bin="#{genv.protk_bin}/correct_omssa_retention_times.rb"
current_db=search_tool.current_database :fasta
fragment_tol = search_tool.fragment_tol
precursor_tol = search_tool.precursor_tol



# Set the search type (monoisotopic vs average masses)
#
if ( search_tool.precursor_search_type=="monoisotopic")
  if ( search_tool.strict_monoisotopic_mass )
    search_type_option="-tem 0 -teppm"
  else
    search_type_option="-tem 4 -teppm"  
  end
else
  search_type_option="-tem 1"
end

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
    cmd= "#{omssa_bin} -d #{current_db} -to #{fragment_tol} #{search_type_option} -te #{search_tool.precursor_tol}  -v #{search_tool.missed_cleavages} -fm #{input_path} -op #{output_path} -he 100000 -w"

    p cmd

    # Add options related to peptide modifications
    #
    if ( search_tool.glyco )
      cmd << " -mv 119 "
    end

    if ( search_tool.respect_precursor_charges )
      cmd << " -zcc 1"
    end

    if ( search_tool.has_modifications )
      cmd << " -mf "
      if ( search_tool.carbamidomethyl )
        cmd<<"3 "
      end

      if ( search_tool.methionine_oxidation )
        cmd<<"1 "
      end

    end
    
    # Add retention time corrections
    #
    if (search_tool.options.add_retention_times)
      cmd << "; #{rt_correct_bin} #{output_path} #{input_path} "
    end
    
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