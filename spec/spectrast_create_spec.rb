require 'spec_helper'
require 'commandline_shared_examples.rb'

def spectrast_installed
	installed=(%x[which spectrast].length>0)
	installed
end

describe "The spectrast_create command" do

	# include_context :tmp_dir_with_fixtures, [
	# 	"spectrast/mr208-HeLa24hx1_GB3_01_8451.d.mzML", 
	# 	"spectrast/mr208-HeLa24hx1_GB3_01_8453.d.mzML", 
	# 	"spectrast/mr208_845_13_iproph.pepXML"]

	describe ["spectrast_create.rb"] do
		it_behaves_like "a protk tool"
	end

end

