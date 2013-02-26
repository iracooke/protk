#
# Created by John Chilton
#
# Run ASAPRatio against protein prophet results.
#
#
#!/bin/sh
PROTK_DIR="$( cd "$( dirname "$0" )" && pwd )"
. $PROTK_DIR/run_protk.sh

#! ruby
#

require 'constants'
require 'protxml'
require 'galaxy_util'

for_galaxy = GalaxyUtil.for_galaxy?

protxml_path = ARGV.shift

if for_galaxy
  protxml_path = GalaxyUtil.stage_protxml(protxml_path)
end

protxml = ProtXML.new(protxml_path)
pepxml_path = protxml.find_pep_xml()

genv=Constants.new

command="#{genv.tpp_bin}/ASAPRatioPeptideParser '#{pepxml_path}' #{ARGV.join(" ")} ; #{genv.tpp_bin}/ASAPRatioProteinRatioParser '#{protxml_path}'; #{genv.tpp_bin}/ASAPRatioPvalueParser '#{protxml_path}' "
%x[#{command}]