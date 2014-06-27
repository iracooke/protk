require 'spec_helper'
require 'commandline_shared_examples.rb'

def tpp_installed
	installed=(%x[which xinteract].length>0)
	installed
end

describe "The peptide_prophet command" do

	include_context :tmp_dir_with_fixtures, [
		"mr176-BSA100fmole_BA3_01_8168.d_tandem.pep.xml",
		"mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml",
		"AASequences.fasta"]

	let(:db_file) { "#{@tmp_dir}/AASequences.fasta" }
	let(:extra_args) { "-d #{db_file}" }
	let(:input_file) { "#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d_tandem.pep.xml" }
	let(:input_files) { ["#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d_tandem.pep.xml",
			"#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"] }
	let(:output_ext) {".pep.xml"}
	let(:suffix) {"_pproph"}
	let(:tmp_dir) {@tmp_dir}
	let(:validator) { be_pepxml } 				

	describe ["peptide_prophet.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["peptide_prophet.rb"] , :dependencies_installed => tpp_installed do
		
		it_behaves_like "a protk tool with default file output" do
			let(:validator1) { have_pepxml_hits_matching(34,/./) }
		end
		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.pep.xml" }
			let(:validator) { have_pepxml_hits_matching(34,/./) }
		end
		it_behaves_like "a protk tool that merges multiple inputs" 

		it_behaves_like "a protk tool that handles multiple inputs sequentially" do
			let(:extra_args) { "-d #{db_file} -F" }
		end

	end

	describe ["peptide_prophet.rb"] , :dependencies_installed => tpp_installed do

		include_context :galaxy_working_dir_with_fixtures, {
			"mr176-BSA100fmole_BA3_01_8168.d_tandem.pep.xml" => "dataset_1.dat",
			"AASequences.fasta" => "dataset_2.dat"
		}

		let(:input_file) { "#{@galaxy_db_dir}/dataset_1.dat" }
		let(:db_file) { "#{@galaxy_db_dir}/dataset_2.dat" }
		let(:working_dir) { @galaxy_work_dir }

		it_behaves_like "a protk tool that works with galaxy",:dependencies_installed => tpp_installed do
			let(:extra_args) {"--galaxy -d #{db_file} "}
			let(:output_file) { "out.pep.xml" }
			let(:validator) { have_lines_matching(1,Regexp.new("#{input_file}")) }
		end

	end

end

