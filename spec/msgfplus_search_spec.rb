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

end

