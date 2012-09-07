require 'pepxml'
require 'galaxy_stager'
require 'galaxy_util'
require 'convert_util'
require 'fileutils'

class GalaxyUtil

  def self.for_galaxy?
    for_galaxy = ARGV[0] == "--galaxy"
    ARGV.shift if for_galaxy
    return for_galaxy
  end


  def self.stage_protxml(input_protxml_path)
    # This method takes in the path to a protxml created in Galaxy,
    # finds the dependent pepxml and peak lists (mzml files), creates
    # symbolic links to the peak lists with the correct extension and
    # and indexes them if needed (both seem required for TPP quant
    # tools) and then produces new protxml and pepxml files with paths
    # updated to these new peak list files.

    protxml_path="interact.prot.xml"
    FileUtils.copy(input_protxml_path, "interact.prot.xml")

    protxml = ProtXML.new(protxml_path)
    pepxml_path = protxml.find_pep_xml()

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

    protxml_path
  end

end
