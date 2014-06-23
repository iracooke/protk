require 'spec_helper'
require 'commandline_shared_examples.rb'

def tandem2xml_not_installed
	installed=(%x[which Tandem2XML].length>0)
	!installed
end

describe "The tandem_to_pepxml tool" do

	include_context :tmp_dir_with_fixtures, ["mr176-BSA100fmole_BA3_01_8167.d_tandem.tandem"]

	before(:each) do
		@input_file="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.tandem"
		@db_file=""
		@extra_args=""
		@output_file="#{@tmp_dir}/out.pep.xml"
	end

	describe ["tandem_to_pepxml.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["tandem_to_pepxml.rb",".pep.xml",""], :dependencies_not_installed => tandem2xml_not_installed do
		it_behaves_like "a protk tool with default file output"
	end

	it "Support the -o option", :dependencies_not_installed => tandem2xml_not_installed do
		%x[tandem_to_pepxml.rb #{@input_file} -o #{@output_file}]
		expect(@output_file).to exist?
	end

end