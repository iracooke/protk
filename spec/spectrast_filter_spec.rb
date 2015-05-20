require 'spec_helper'
require 'commandline_shared_examples.rb'

def spectrast_installed
	installed=(%x[which spectrast].length>0)
	installed
end

describe "The spectrast_filter command" do

	describe ["spectrast_filter.rb"] do
		it_behaves_like "a protk tool"
	end

end

