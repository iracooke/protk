require 'spec_helper'
require 'commandline_shared_examples.rb'

def msgfplus_installed
	installed=(%x[which MSGFPlus.jar].length>0)
	installed
end

describe "The msgfplus_search command" do

	include_context :tmp_dir_with_fixtures, ["tiny.mzML","testdb.fasta"]

	describe ["msgfplus_search.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["msgfplus_search.rb"] , :dependencies_installed => msgfplus_installed do
		let(:db_file) { "#{@tmp_dir}/testdb.fasta" }
		let(:extra_args) { "-d #{db_file} -p 200" }
		let(:input_file) { "#{@tmp_dir}/tiny.mzML" }
		let(:output_ext) {".mzid"}
		let(:suffix) {"_msgfplus"}
		let(:validator) { be_mzidentml }
		let(:tmp_dir) {@tmp_dir}
		
		it_behaves_like "a protk tool with default file output"
		it_behaves_like "a protk tool with default file output" do
			let(:extra_args) { "-d #{db_file} -p 200 --pepxml" }
			let(:validator) { be_pepxml }
			let(:output_ext) {".pep.xml"}
		end

	end

	describe ["msgfplus_search.rb"] , :dependencies_installed => msgfplus_installed do

		include_context :galaxy_working_dir_with_fixtures, { 
			"tiny.mzML" => "dataset_1.dat",
			"testdb.fasta" => "dataset_2.dat"}

		let(:input_file) { "#{@galaxy_db_dir}/dataset_1.dat" }
		let(:db_file) { "#{@galaxy_db_dir}/dataset_2.dat" }
		let(:working_dir) { @galaxy_work_dir }

		it_behaves_like "a protk tool that works with galaxy",:dependencies_installed => msgfplus_installed do
			let(:extra_args) {"--galaxy -d #{db_file} "}
			let(:output_file) { "out.mzid" }
			let(:validator) { have_lines_matching(1,Regexp.new("#{input_file}")) }
			let(:validator1) { have_lines_matching(0,Regexp.new("galaxy_job_working_dir")) }
			let(:validator2) { have_lines_matching(0,Regexp.new("tiny.mzML")) }			
		end

		it_behaves_like "a protk tool that works with galaxy",:dependencies_installed => msgfplus_installed do
			let(:extra_args) {"--galaxy -d #{db_file} --pepxml"}
			let(:output_file) { "out.pep.xml" }
			# let(:validator) { have_lines_matching(1,Regexp.new("#{input_file}")) }
			let(:validator1) { have_lines_matching(0,Regexp.new("galaxy_job_working_dir")) }
			let(:validator2) { have_lines_matching(0,Regexp.new("tiny.mzML")) }
		end

	end


end

