#
# Created by John Chilton
#
# Run libra quantification against protein prophet results.
#
#
#!/bin/sh
. `dirname \`readlink -f $0\``/protk_run.sh
#! ruby
#

require 'constants'
require 'protxml'
require 'pepxml'
require 'galaxy_stager'
require 'galaxy_util'
require 'convert_util'
require 'fileutils'

for_galaxy = GalaxyUtil.for_galaxy

input_protxml_path = ARGV[0]
protxml_path="interact.prot.xml"
FileUtils.copy(input_protxml_path, "interact.prot.xml")

ARGV.shift
protxml = ProtXML.new(protxml_path)
pepxml_path = protxml.find_pep_xml()

if for_galaxy
  # Stage files for galaxy
  protxml_stager = GalaxyStager.new(protxml_path, :extension => ".prot.xml", :force_copy => true)
  pepxml_stager = GalaxyStager.new(pepxml_path, :extension => ".pep.xml", :force_copy => true)
  pepxml_path = pepxml_stager.staged_path
  pepxml_stager.replace_references(protxml_path)
  runs = PepXML.new(pepxml_stager.staged_path).find_runs()
  
  run_stagers = runs.map do |base_name, run|
    run_stager = GalaxyStager.new(base_name, :extension => ".#{run[:type]}")
    ConvertUtil.ensure_mzml_indexed(run_stager.staged_path)
    run_stager.replace_references(pepxml_path, :base_only => true)
    run_stager
  end

end

genv=Constants.new

condition_file = ARGV[0]
ARGV.shift
command="#{genv.tpp_bin}/LibraPeptideParser #{pepxml_path} -c#{condition_file}; #{genv.tpp_bin}/LibraProteinRatioParser #{protxml_path} -c#{condition_file}"
%x[#{command}]
