#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 30/4/2015
#
# A wrapper for the SpectraST create command
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/galaxy_util'
require 'protk/pepxml'
require 'protk/sniffer'
require 'protk/mzml_parser'

for_galaxy = GalaxyUtil.for_galaxy?

genv=Constants.instance

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
spectrast_tool=Tool.new([:explicit_output])
spectrast_tool.option_parser.banner = "Create a spectral library from pep.xml input files.\n\nUsage: spectrast_create.rb [options] file1.pep.xml file1.pep.xml ..."
spectrast_tool.add_value_option(:spectrum_files,"",['--spectrum-files sf','Paths to raw spectrum files. These should be provided in a comma separated list'])
spectrast_tool.add_boolean_option(:binary_output,false,['-B','--binary-output','Produce spectral libraries in binary format rather than ASCII'])
spectrast_tool.add_value_option(:filter_predicate,nil,['--predicate pred','Keep only spectra satifying predicate pred. Should be a C-style predicate'])
spectrast_tool.add_value_option(:probability_threshold,0.99,['--p-thresh val', 'Probability threshold below which spectra are discarded'])
spectrast_tool.add_value_option(:instrument_acquisition,"CID",['--instrument-acquisition setting', 
								'Set the instrument and acquisition settings of the spectra (in case not specified in data files).
	                             Examples: CID, ETD, CID-QTOF, HCD. The latter two are treated as high-mass accuracy spectra.'])

exit unless spectrast_tool.check_options(true)

spectrast_bin = %x[which spectrast].chomp

# Options: GENERAL OPTIONS
#          -cF<file>    Read create options from file <file>. 
#                            If <file> is not given, "spectrast_create.params" is assumed.
#                            NOTE: All options set in the file will be overridden by command-line options, if specified.
#          -cm<remark>  Remark. Add a Remark=<remark> comment to all library entries created. 
#          -cM<format>  Write all library spectra as MRM transition tables. Leave <format> blank for default. (Turn off with -cM!) 
#          -cT<file>    Use probability table in <file>. Only those peptide ions included in the table will be imported. 
#                            A probability table is a text file with one peptide ion in the format AC[160]DEFGHIK/2 per line. 
#                            If a probability is supplied following the peptide ion separated by a tab, it will be used to replace the original probability of that library entry.
#          -cO<file>    Use protein list in <file>. Only those peptide ions associated with proteins in the list will be imported. 
#                            A protein list is a text file with one protein identifier per line. 
#                            If a number X is supplied following the protein separated by a tab, then at most X peptide ions associated with that protein will be imported.

#          PEPXML IMPORT OPTIONS (Applicable with .pepXML files)
#          -cP<prob>    Include all spectra identified with probability no less than <prob> in the library.
#          -cq<fdr>     (Only PepXML import) Only include spectra with global FDR no greater than <fdr> in the library.
#          -cn<name>    Specify a dataset identifier for the file to be imported.
#          -co          Add the originating mzXML file name to the dataset identifier. Good for keeping track of in which
#                            MS run the peptide is observed. (Turn off with -co!)
#          -cg          Set all asparagines (N) in the motif NX(S/T) as deamidated (N[115]). Use for glycocaptured peptides. (Turn off with -cg!).
#          -cI          Set the instrument and acquisition settings of the spectra (in case not specified in data files).
#                            Examples: -cICID, -cIETD, -cICID-QTOF, -cIHCD. The latter two are treated as high-mass accuracy spectra.
#                            

# -cf<pred>    Filter library. Keep only those entries satisfying the predicate <pred>. 
#                            <pred> should be a C-style predicate in quotes. 

input_stagers=[]
inputs=ARGV.collect { |file_name| file_name.chomp}
if for_galaxy
  input_stagers = inputs.collect {|ip| GalaxyUtil.stage_pepxml(ip) }
  inputs=input_stagers.collect { |sg| sg.staged_path }
end

spectrum_file_paths=spectrast_tool.spectrum_files.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }

spectrum_file_paths.each do |rf| 
	throw "Provided spectrum file #{rf} does not exist" unless File.exists? rf
	format = Sniffer.sniff_format(rf)
	throw "Unrecognised format #{format} detected for spectrum file #{rf}" unless ["mzML","mgf"].include? format

	# basename_no_ext = File.basename(rf,File.extname(rf))
	runid_name = MzMLParser.new(rf).next_runid()

	expected_name = "#{runid_name}.#{format}"

	if for_galaxy || !File.exists?(expected_name)
		raw_input_stager = GalaxyStager.new(rf,{:extension=>".#{format}",:name=>runid_name})
		puts raw_input_stager.staged_path
	end

end


cmd="#{spectrast_bin} "

unless spectrast_tool.binary_output
	cmd << " -c_BIN!"	
end

if spectrast_tool.filter_predicate
	cmd << "  -cf'#{spectrast_tool.filter_predicate}'"	
end



cmd << " -cI#{spectrast_tool.instrument_acquisition}"

if spectrast_tool.explicit_output==nil
    output_file_name=Tool.default_output_path(inputs,"","","")
else
    output_file_name=spectrast_tool.explicit_output
end

cmd << " -cN#{output_file_name}"

cmd << " -cP#{spectrast_tool.probability_threshold}"

inputs.each { |ip| cmd << " #{ip}" }

# code = spectrast_tool.run(cmd,genv)
# throw "Command failed with exit code #{code}" unless code==0

%x[#{cmd}]




