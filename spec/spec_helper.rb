require 'bundler/setup'
Bundler.setup

require 'protk'


	
$protk_env=Constants.new
$this_dir=File.dirname(__FILE__)


def swissprot_installed
	Pathname.new("#{$protk_env.protein_database_root}/#{$protk_env.uniprot_sprot_annotation_database}").exist?
end

def blast_installed
	$protk_env.makeblastdb!=nil
end

RSpec.configure do |c|
	c.filter_run_excluding :broken => true unless (swissprot_installed && blast_installed)
  c.filter_run_excluding :dependencies_not_installed => true  
end

RSpec::Matchers.define :exist? do
 	match do |filename|
   		File.exist?(filename)
  	end
end

RSpec::Matchers.define :contain_text  do |match_text|
  match do |filename|
    File.read(filename).include?(match_text)
  end
end


RSpec.shared_context :tiny_inputs_and_outputs do 

  before(:each) do
    @tmp_dir=Dir.mktmpdir

    ["tiny.mzML","testdb.fasta"].each do |file| 
      file_path=Pathname.new("#{$this_dir}/data/#{file}").realpath.to_s
      throw "test file #{file} does not exist" unless File.exist? file_path
      File.symlink(file_path,"#{@tmp_dir}/#{file}")
    end

    @tiny_input="#{@tmp_dir}/tiny.mzML"
    @db_file = "#{@tmp_dir}/testdb.fasta"
    @output_file="#{@tmp_dir}/tiny_tandem.tandem"

  end

  after(:each) do
    FileUtils.remove_entry @tmp_dir
  end

end
