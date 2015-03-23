require 'protk/pepxml'
require 'protk/galaxy_stager'
require 'protk/galaxy_util'
require 'protk/convert_util'
require 'fileutils'

class GalaxyUtil

  def self.for_galaxy?    
    fg = ARGV[0]=="--galaxy"
    ARGV.shift if fg
    fg
  end

  def self.stage_pepxml(input_pepxml_path,options={})
    options = { :extension => '.pep.xml', :force_copy => false }.merge(options)
    GalaxyStager.new(input_pepxml_path, options )
  end

  def self.stage_fasta(input_path,options={})
    options = { :extension => '.fasta', :force_copy => false }.merge(options)
    GalaxyStager.new(input_path, options )
  end
  

    # Galaxy changes things like @ to __at__ we need to change it back
    #
    def self.decode_galaxy_string!(mstring)
        mstring.gsub!("__at__","@")
        mstring.gsub!("__oc__","{")
        mstring.gsub!("__cc__","}")
        mstring.gsub!("__ob__","[")
        mstring.gsub!("__cb__","]")
        mstring.gsub!("__gt__",">")
        mstring.gsub!("__lt__","<")
        mstring.gsub!("__sq__","'")
        mstring.gsub!("__dq__","\"")
        mstring.gsub!("__cn__","\n")
        mstring.gsub!("__cr__","\r")
        mstring.gsub!("__tc__","\t")
        mstring.gsub!("__pd__","#")

        # For characters not allowed at all by galaxy
        mstring.gsub!("__pc__","|")

        mstring
    end


  # Unused

  # def self.stage_protxml(input_protxml_path)
  #   # This method takes in the path to a protxml created in Galaxy,
  #   # finds the dependent pepxml and peak lists (mzml files), creates
  #   # symbolic links to the peak lists with the correct extension and
  #   # and indexes them if needed (both seem required for TPP quant
  #   # tools) and then produces new protxml and pepxml files with paths
  #   # updated to these new peak list files.

  #   protxml_path="interact.prot.xml"
  #   FileUtils.copy(input_protxml_path, "interact.prot.xml")

  #   protxml = ProtXML.new(protxml_path)
  #   pepxml_path = protxml.find_pep_xml()

  #   protxml_stager = GalaxyStager.new(protxml_path, :extension => ".prot.xml", :force_copy => true)
  #   pepxml_stager = GalaxyStager.new(pepxml_path, :name => "interact", :extension => ".xml", :force_copy => true)
  #   pepxml_path = pepxml_stager.staged_path
  #   pepxml_stager.replace_references(protxml_path)
  #   runs = PepXML.new(pepxml_stager.staged_path).find_runs()
  
  #   run_stagers = runs.map do |base_name, run|
  #     run_stager = GalaxyStager.new(base_name, :extension => ".#{run[:type]}")
  #     ConvertUtil.ensure_mzml_indexed(run_stager.staged_path)
  #     run_stager.replace_references(pepxml_path, :base_only => true)
  #     run_stager
  #   end

  #   protxml_path
  # end




end
