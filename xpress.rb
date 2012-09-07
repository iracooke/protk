#
# Created by John Chilton
#
# Run XPRESS against protein prophet results.
#
#
#!/bin/sh
PROTK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
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

command="#{genv.tpp_bin}/XPressPeptideParser '#{pepxml_path}' #{ARGV.join(" ")} ; #{genv.tpp_bin}/XPressProteinRatioParser '#{protxml_path}'"
%x[#{command}]
