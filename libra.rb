#
# Created by John Chilton
#
# Run libra quantification against protein prophet results.
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

condition_file = ARGV.shift

command="#{genv.tpp_bin}/LibraPeptideParser '#{pepxml_path}' -c#{condition_file}; #{genv.tpp_bin}/LibraProteinRatioParser '#{protxml_path}' -c#{condition_file}"
%x[#{command}]
