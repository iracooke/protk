require 'libxml'
require 'protk/constants'

class ConvertUtil

  def self.ensure_mzml_indexed(run_file)
    if unindexed_mzml?(run_file)
      index_mzml(run_file)
    end
  end

  def self.index_mzml(mzml_file)
    Dir.mktmpdir do |tmpdir|
      genv=Constants.instance
      %x["#{genv.msconvert} -o #{tmpdir} #{mzml_file}"]
      indexed_file = Dir["#{tmpdir}/*"][0]
      FileUtils.mv(indexed_file, mzml_file)
    end
  end
  
  def self.unindexed_mzml?(mzml_file)
    reader = LibXML::XML::Reader.file(mzml_file)
    reader.read
    reader.name == "mzML"
  end

end
