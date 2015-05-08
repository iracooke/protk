require 'bundler/setup'
Bundler.setup

require 'protk'


	
$protk_env=Constants.instance
$this_dir=File.dirname(__FILE__)


def swissprot_installed
	Pathname.new("#{$protk_env.protein_database_root}/#{$protk_env.uniprot_sprot_annotation_database}").exist?
end

def blast_installed
	$protk_env.makeblastdb!=nil
end

RSpec.configure do |c|
	c.filter_run_excluding :broken => true unless (swissprot_installed && blast_installed)
  c.filter_run_excluding :dependencies_installed => false 
end

RSpec::Matchers.define :exist? do
 	match do |filename|
   	File.exist?(filename)
  end

  failure_message do |filename|
    listing=%x[ls #{Pathname.new(filename).dirname.to_s}]
    "\nLooking for #{filename}. Did you mean one of these files:\n#{listing} in #{Pathname.new(filename).dirname.expand_path.to_s}\n"
  end

end

RSpec::Matchers.define :have_attribute_with_value  do |attribute_name,value|
  match do |xmlnode|
    xmlnode.attributes["#{attribute_name}"]==value
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


RSpec::Matchers.define :be_fasta  do
  match do |filename|
    is_fasta=false
    is_fasta = ( File.new(filename).readline =~ /^>/ )
    is_fasta
  end
end


RSpec::Matchers.define :have_lines_matching  do |expected_num_lines,pattern|
  match do |filename|
    @n_entries=0
    if File.exists?(filename)
      content=File.read(filename)
    else
      content=filename
    end
    content.each_line do |line|
      # puts line
      if line =~/#{pattern}/
        # puts line
        @n_entries+=1
      end
    end
    @n_entries==expected_num_lines
  end

  failure_message do
    "\nexpected #{expected_num_lines} but found #{@n_entries} lines matching #{pattern}\n"
  end

end

RSpec::Matchers.define :have_pepxml_hits_matching  do |expected_num_entries,pattern|
  match do |filename|
    filename.chomp!
    pepxml_parser=XML::Parser.file(filename)
    pepxml_ns_prefix="xmlns:"
    pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"
    pepxml_doc=pepxml_parser.parse
    hits=pepxml_doc.find("//#{pepxml_ns_prefix}search_hit", pepxml_ns)

    @n_entries=0
    hits.each do |hit_node|  
      if hit_node.to_s =~/#{pattern}/
        @n_entries+=1
      end
    end
    @n_entries==expected_num_entries
  end

  failure_message do
    "\nexpected #{expected_num_entries} but found #{@n_entries} hits matching #{pattern}\n"
  end

end


RSpec::Matchers.define :be_pepxml  do
  match do |filename|
    filename.chomp!
    File.read(filename).include?('http://regis-web.systemsbiology.net/pepXML')
  end

  failure_message do |filename|
    "\nExpected pepXML but got #{File.read(filename)}\n"
  end
end

RSpec::Matchers.define :be_mzidentml  do
  match do |filename|
    filename.chomp!
    File.read(filename).include?('http://psidev.info/psi/pi/mzIdentML')
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


RSpec.shared_context :galaxy_working_dir_with_fixtures do |filename_mappings|

  before(:each) do

    # Make a tmp dir to represent the galaxy data dir
    #
    @galaxy_db_dir=Dir.mktmpdir("galaxy_database_dir")

    # This will be the working dir
    @galaxy_work_dir=Dir.mktmpdir("galaxy_job_working_dir")

    filename_mappings.each_pair do |original,final| 
      original_path=Pathname.new("#{$this_dir}/data/#{original}").realpath.to_s
      throw "test file #{original} does not exist" unless File.exist? original_path
      FileUtils.copy(original_path,"#{@galaxy_db_dir}/#{final}")
    end

  end

  after(:each) do
    FileUtils.remove_entry @galaxy_work_dir
    FileUtils.remove_entry @galaxy_db_dir
  end

end
