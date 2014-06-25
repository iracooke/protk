require 'spec_helper'
require 'commandline_shared_examples.rb'

def tandem2xml_installed
	installed=(%x[which Tandem2XML].length>0)
	installed
end

describe "The tandem_to_pepxml tool" do

	include_context :tmp_dir_with_fixtures, ["mr176-BSA100fmole_BA3_01_8167.d_tandem.tandem"]


	let(:input_file) {"#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.tandem"}
	let(:extra_args) {""}
	let(:suffix) { ""}
	let(:output_ext) {".pep.xml"}
	let(:tmp_dir) {@tmp_dir}
	
	describe ["tandem_to_pepxml.rb"]  do
		it_behaves_like "a protk tool"
	end


	describe ["tandem_to_pepxml.rb"] , :dependencies_installed => tandem2xml_installed do
		it_behaves_like "a protk tool"
		it_behaves_like "a protk tool with default file output"		
		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.txt" }
			let(:validator) { have_lines_matching(182,"search_hit") }
		end
	end

end