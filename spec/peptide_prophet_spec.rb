require 'spec_helper'
require 'commandline_shared_examples.rb'

def tpp_installed
	installed=(%x[which xinteract].length>0)
	installed
end

describe "The peptide_prophet command", :broken => false do

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
	let(:validator) { be_pepxml } 				

	describe ["peptide_prophet.rb"] do
		it_behaves_like "a protk tool"
		it_behaves_like "a protk tool with default file output", :dependencies_installed => tpp_installed do
			let(:validator1) { have_pepxml_hits_matching(34,/./) }
		end
		it_behaves_like "a protk tool that supports explicit output", :dependencies_installed => tpp_installed do
			let(:output_file) { "#{@tmp_dir}/out.pep.xml" }
			let(:validator) { have_pepxml_hits_matching(34,/./) }
		end
		it_behaves_like "a protk tool with default file output from multiple inputs", :dependencies_installed => tpp_installed 

	end

	it "supports the -F (one at a time) option", :dependencies_installed => tpp_installed do
		output_files= input_files.collect { |f| Tool.default_output_path(f,output_ext,"",suffix)}

		%x[peptide_prophet.rb -d #{db_file} #{input_files[0]} #{input_files[1]} -F]

		output_files.each do |f|  
			expect(f).to exist?
			expect(f).to be_pepxml
		end

	end

end

