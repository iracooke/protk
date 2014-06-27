require 'spec_helper'
require 'commandline_shared_examples.rb'

def omssa_installed
	installed=(%x[which omssacl].length>0)
	installed
end

describe "The omssa_search command", :broken => false do

	include_context :tmp_dir_with_fixtures, ["mr176-BSA100fmole_BA3_01_8168.d.mgf","AASequences.fasta"]

	describe ["omssa_search.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["omssa_search.rb"] , :dependencies_installed => omssa_installed do

		let(:db_file) { "#{@tmp_dir}/AASequences.fasta" }
		let(:extra_args) { "-d #{db_file} --max-hit-expect 1000" }
		let(:input_file) { "#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d.mgf" }
		let(:output_ext) {".pep.xml"}
		let(:suffix) {"_omssa"}
		let(:tmp_dir) {@tmp_dir}
		
		it_behaves_like "a protk tool with default file output"
		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.pep.xml" }
			let(:validator) { have_lines_matching(10,"search_hit") }
		end
	end


	describe ["omssa_search.rb"] , :dependencies_installed => omssa_installed do

		include_context :galaxy_working_dir_with_fixtures, { 
			"mr176-BSA100fmole_BA3_01_8168.d.mgf" => "dataset_1.dat",
			"AASequences.fasta" => "dataset_2.dat"}

		let(:input_file) { "#{@galaxy_db_dir}/dataset_1.dat" }
		let(:db_file) { "#{@galaxy_db_dir}/dataset_2.dat" }
		let(:working_dir) { @galaxy_work_dir }

		it_behaves_like "a protk tool that works with galaxy",:dependencies_installed => omssa_installed do
			let(:extra_args) {"-d #{db_file} "}
			let(:output_file) { "out.pep.xml" }
			let(:validator) { have_lines_matching(1,Regexp.new("#{input_file}")) }
			let(:validator1) { have_lines_matching(0,Regexp.new("galaxy_job_working_dir")) }
			let(:validator2) { have_lines_matching(0,Regexp.new("mr176-BSA100fmole_BA3_01_8168.d.mgf")) }			
		end

	end



end

