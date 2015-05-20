#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 30/4/2015
#
# A wrapper for SpectraST commands that manipulate splib files 
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?

genv=Constants.instance

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
spectrast_tool=Tool.new([:explicit_output])
spectrast_tool.option_parser.banner = "Manipulate splib files.\n\nUsage: spectrast_filter.rb [options] file1.splib file1.splib ..."
spectrast_tool.add_boolean_option(:binary_output,false,['-B','--binary-output','Produce spectral libraries in binary format rather than ASCII'])
spectrast_tool.add_value_option(:filter_predicate,nil,['--predicate pred','Keep only spectra satifying predicate pred. Should be a C-style predicate'])
spectrast_tool.add_value_option(:merge_operation,"U",['--merge method',
								'How to combine multiple splib files (if provided). Options are U,S,H
				     U: Union. Include all the peptide ions in all the files.
				     S: Subtraction. Only include peptide ions in the first file 
				     	that are not present in any of the other files.
				     H: Subtraction of homologs. Only include peptide ions in the
				     	first file that do not have any homologs with 
				     	same charge and similar m/z in any of the other files.
				     A: Appending. Each peptide ion is added from only one library: 
				     	the first file in the argument list that contains that peptide ion.
				     	Useful for keeping existing consensus spectra unchanged while adding
				     	only previously unseen peptide ions.'])
spectrast_tool.add_value_option(:spectrum_operation,"None",['--replicates method',
								'How to derive a single spectrum from replicates. Options are None, C,B
				     C: Consensus. Create the consensus spectrum of all replicate spectra of each peptide ion.
				     B: Best replicate. Pick the best replicate of each peptide ion.'])

exit unless spectrast_tool.check_options(true)

spectrast_bin = %x[which spectrast].chomp

        # LIBRARY MANIPULATION OPTIONS (Applicable with .splib files)
        #  -cf<pred>    Filter library. Keep only those entries satisfying the predicate <pred>. 
        #                    <pred> should be a C-style predicate in quotes. 
        #  -cJU         Union. Include all the peptide ions in all the files. 
        #  -cJI         Intersection. Only include peptide ions that are present in all the files. 
        #  -cJS         Subtraction. Only include peptide ions in the first file that are not present in any of the other files.
        #  -cJH         Subtraction of homologs. Only include peptide ions in the first file 
        #                    that do not have any homologs with same charge and similar m/z in any of the other files.
        #  -cJA         Appending. Each peptide ion is added from only one library: the first file in the argument list that contains that peptide ion.
        #                    Useful for keeping existing consensus spectra unchanged while adding only previously unseen peptide ions.
        #  -cAB         Best replicate. Pick the best replicate of each peptide ion. 
        #  -cAC         Consensus. Create the consensus spectrum of all replicate spectra of each peptide ion. 
        #  -cAQ         Quality filter. Apply quality filters to library.
        #                    IMPORTANT: Quality filter can only be applied on a SINGLE .splib file with no peptide ion represented by more than one spectrum.
        #  -cAD         Create artificial decoy spectra. 
        #  -cAN         Sort library entries by descending number of replicates used (tie-breaking by probability). 
        #  -cAM         Create semi-empirical spectra based on allowable modifications specified by -cx option. 
        #  -cQ<num>     Produce reduced spectra of at most <num> peaks. Inactive with -cAQ and -cAD.
        #  -cD<file>    Refresh protein mappings of each library entry against the protein database <file> (Must be in .fasta format).
        #  -cu          Delete entries whose peptide sequences do not map to any protein during refreshing with -cD option.
        #                    When off, unmapped entries will be marked with Protein=0/UNMAPPED but retained in library. (Turn off with -cu!).
        #  -cd          Delete entries whose peptide sequences map to multiple proteins during refreshing with -cD option. (Turn off with -cd!).

input_stagers=[]
inputs=ARGV.collect { |file_name| file_name.chomp}
if for_galaxy
  input_stagers = inputs.collect {|ip| GalaxyStager.new(ip,{:extension=>".splib"}) }
  inputs=input_stagers.collect { |sg| sg.staged_path }
end


cmd="#{spectrast_bin} "

unless spectrast_tool.binary_output
	cmd << " -c_BIN!"	
end

if spectrast_tool.filter_predicate
	cmd << "  -cf'#{spectrast_tool.filter_predicate}'"	
end

if inputs.length > 1
	cmd << " -cJ#{spectrast_tool.merge_operation}"
end

if spectrast_tool.spectrum_operation!="None"
	cmd << " -cA#{spectrast_tool.spectrum_operation}"
end

if spectrast_tool.explicit_output==nil
    output_file_name=Tool.default_output_path(inputs,"","","")
else
    output_file_name=spectrast_tool.explicit_output
end

cmd << " -cN#{output_file_name}"

inputs.each { |ip| cmd << " #{ip}" }

# code = spectrast_tool.run(cmd,genv)
# throw "Command failed with exit code #{code}" unless code==0

%x[#{cmd}]
