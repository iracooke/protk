#!/usr/bin/env ruby
#
# Created by John Chilton
#
# Run ASAPRatio against protein prophet results.
#
#

require 'protk/constants'
require 'protk/protxml'
require 'protk/galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?

protxml_path = ARGV.shift

if for_galaxy
  protxml_path = GalaxyUtil.stage_protxml(protxml_path)
end

protxml = ProtXML.new(protxml_path)
pepxml_path = protxml.find_pep_xml()

genv=Constants.new

command="#{genv.asapratiopeptideparser} '#{pepxml_path}' #{ARGV.join(" ")} ; #{genv.asapratioproteinparser} '#{protxml_path}'; #{genv.asaprationpvalueparser} '#{protxml_path}' "
%x[#{command}]
