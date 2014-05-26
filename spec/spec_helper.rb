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
end


RSpec::Matchers.define :be_a_non_empty_file do
 	match do |filename|
   		File.exist?(filename)
  	end
end

RSpec::Matchers.define :exist? do
 	match do |filename|
   		File.exist?(filename)
  	end
end

RSpec.shared_context :tmp_dir_with_files do |input_files|
  before(:each) do
  	@tmp_dir=Dir.mktmpdir
  	input_files.each do |file| 
  		file_path=Pathname.new("#{$this_dir}/data/#{file}").realpath.to_s
  		throw "test file #{file} does not exist" unless File.exist? file_path
  		File.symlink(file_path,"#{@tmp_dir}/#{file}")
  	end
  end

end

