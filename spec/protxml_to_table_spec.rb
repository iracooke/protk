require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The protxml_to_table command" do

	include_context :tmp_dir_with_fixtures, [
		"mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph_protproph.prot.xml",
		"mr176-BSA100fmole_BA3_01_8168.d_tandem_pproph_protproph.prot.xml"]

	let(:extra_args) { ""}
	let(:input_files) { [
		"#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph_protproph.prot.xml",
		"#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph_protproph.prot.xml"] }

	describe ["protxml_to_table.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { input_files[0] }
			let(:validator) { have_lines_matching(3,"DROME") }
		end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:input_file) { input_files[0] }
			let(:output_file) { "#{@tmp_dir}/out.txt" }
			let(:validator) { have_lines_matching(3,"DROME") }
		end

	end

end

