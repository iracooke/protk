require 'spec_helper'
require 'commandline_shared_examples.rb'

def tpp_not_installed
	installed=(%x[which xinteract].length>0)
	!installed
end

describe "The peptide_prophet command", :broken => false do

	include_context :tmp_dir_with_fixtures, [
		"mr176-BSA100fmole_BA3_01_8168.d_tandem.pep.xml",
		"mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml",
		"AASequences.fasta"]

	before(:each) do
		@input_file="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d_tandem.pep.xml"
		@input_file_1="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"
		@db_file="#{@tmp_dir}/AASequences.fasta"
		@extra_args="-d #{@db_file}"
		@output_file="#{@tmp_dir}/out.pep.xml"
	end

	describe ["peptide_prophet.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["peptide_prophet.rb",".pep.xml","_pproph"], :dependencies_not_installed => tpp_not_installed do
		it_behaves_like "a protk tool with default file output"
	end

	it "produce a named output file with valid content", :dependencies_not_installed => tpp_not_installed do

		%x[peptide_prophet.rb -d #{@db_file} #{@input_file} -o #{@output_file}]
		
		expect(@output_file).to exist?
		expect(@output_file).to be_pepxml		
		expect(@output_file).to have_pepxml_hits_matching(18,/./)
	end

	it "supports the -F (one at a time) option" do
		output_files= [@input_file,@input_file_1].collect { |f| Tool.default_output_path(f,".pep.xml","","_pproph")}

		%x[peptide_prophet.rb -d #{@db_file} #{@input_file} #{@input_file_1} -F]

		output_files.each do |f|  
			expect(f).to exist?
			expect(f).to be_pepxml
		end

	end

end

