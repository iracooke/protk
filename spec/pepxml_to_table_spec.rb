require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The pepxml_to_table command", :broken => false do

	include_context :tmp_dir_with_fixtures, [
		"mr176-BSA100fmole_BA3_01_8167.d_msgfplus.pep.xml",
		"mr176-BSA100fmole_BA3_01_8167.d_omssa.pep.xml",
		"mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"]

	before(:each) do
		@msgfplus_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_msgfplus.pep.xml"
		@omssa_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_omssa.pep.xml"
		@tandem_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"
	end

	let(:extra_args) { ""}

	describe ["pepxml_to_table.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { @omssa_pepxml }
			let(:validator) { have_lines_matching(2,"OMSSA") }
		end
		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { @tandem_pepxml }
			let(:validator) { have_lines_matching(91,"X! Tandem") }
		end
		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { @msgfplus_pepxml }
			let(:validator) { have_lines_matching(70,"MS-GF") }
		end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:input_file) { @tandem_pepxml }
			let(:output_file) { "#{@tmp_dir}/out.txt" }
			let(:validator) { have_lines_matching(91,"X! Tandem") }
		end

	end

end

