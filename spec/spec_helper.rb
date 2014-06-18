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

RSpec::Matchers.define :have_fasta_entries  do |expected_num_entries|
  match do |filename|
    filename.chomp!
    @n_entries=0
    Bio::FastaFormat.open(filename).each { |e| @n_entries+=1 }
    @n_entries==expected_num_entries
  end
  failure_message do
    "\nexpected #{expected_num_entries} but found #{@n_entries} fasta entries\n"
  end
end

RSpec::Matchers.define :have_fasta_entries_matching  do |expected_num_entries,pattern|
  match do |filename|
    filename.chomp!
    @n_entries=0
    Bio::FastaFormat.open(filename).each do |e| 
      if e.entry_id=~/#{pattern}/
        @n_entries+=1
      end
    end
    @n_entries==expected_num_entries
  end

  failure_message do
    "\nexpected #{expected_num_entries} but found #{@n_entries} fasta entries\n"
  end

end


RSpec.shared_context :tmp_dir_with_fixtures do |filenames|

  before(:each) do

    @tmp_dir=Dir.mktmpdir

    filenames.each do |file| 
      file_path=Pathname.new("#{$this_dir}/data/#{file}").realpath.to_s
      throw "test file #{file} does not exist" unless File.exist? file_path
      File.symlink(file_path,"#{@tmp_dir}/#{file}")
    end

  end

  after(:each) do
    FileUtils.remove_entry @tmp_dir
  end

end
