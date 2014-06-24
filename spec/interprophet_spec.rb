require 'spec_helper'
require 'commandline_shared_examples.rb'

def tpp_installed
	installed=(%x[which xinteract].length>0)
	installed
end

describe "The interprophet tool" do

	include_context :tmp_dir_with_fixtures, [
			"mr176-BSA100fmole_BA3_01_8168.d_tandem_pproph.pep.xml",
			"mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph.pep.xml"
			]


	before(:each) do
		@input_files=[
			"#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d_tandem_pproph.pep.xml",
			"#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph.pep.xml"]
		@db_file="#{@tmp_dir}/AASequences.fasta"
		@output_file="#{@tmp_dir}/out.pep.xml"
		@extra_args=""
	end

	describe ["interprophet.rb"] do
		it_behaves_like "a protk tool"
	end

	# InterProphetParser is broken for this example data
	describe ["interprophet.rb",".pep.xml","_iproph"],:broken=>true, :dependencies_installed => tpp_installed do
		it_behaves_like "a protk tool with default file output from multiple inputs"
	end

end