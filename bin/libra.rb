#!/usr/bin/env ruby
#
# Created by John Chilton
#
# Run libra quantification against protein prophet results.
#
#

require 'protk/constants'
require 'protk/protxml'
require 'protk/galaxy_util'
require 'optparse'

for_galaxy = GalaxyUtil.for_galaxy?

protxml_path = ARGV.shift

if for_galaxy
  protxml_path = GalaxyUtil.stage_protxml(protxml_path)
end

protxml = ProtXML.new(protxml_path)
pepxml_path = protxml.find_pep_xml()

genv=Constants.new

option_parser=OptionParser.new()

reagents = []
mass_tolerance = "0.2"
option_parser.on( '--mass-tolerance TOL',"Specifies the mass tolerance (window libra will search for the most intense m/z value in)." ) do |tol|
  mass_tolerance = tol
end

option_parser.on( '--reagent MZ', "Specify a reagent (via m/z values).") do |reagent|
  reagents << reagent
end

minimum_threshold_string = ""
option_parser.on( '--minimum-threshold THRESH', "Minimum threshhold intensity (not required).") do |thresh|
  minimum_threshold_string = "<minimumThreshhold value=\"#{thresh}\"/>"
end

option_parser.parse!


reagent_strings = reagents.map do |reagent|
  "<reagent mz=\"#{reagent}\" />"
end
reagents_string = reagent_strings.join(" ")

isotopic_contributions = ""

condition_contents = "<SUMmOnCondition description=\"libra_galaxy_run\">
  <fragmentMasses>
    #{reagents_string}
  </fragmentMasses>
  #{isotopic_contributions}
  <massTolerance value=\"#{mass_tolerance}\"/>
  <centroiding type=\"2\" iterations=\"1\"/>
  <normalization type=\"4\"/>
  <targetMs level=\"2\"/>
  <output type=\"1\"/>
  <quantitationFile name=\"quantitation.tsv\"/>
  #{minimum_threshold_string}
</SUMmOnCondition>"
File.open("condition.xml", "w") { |f| f.write(condition_contents) }
print condition_contents
command="#{genv.librapeptideparser} '#{pepxml_path}' -ccondition.xml; #{genv.libraproteinratioparser} '#{protxml_path}' -c#{condition_file}"
%x[#{command}]
