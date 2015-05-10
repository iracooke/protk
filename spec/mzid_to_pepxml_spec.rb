require 'spec_helper'
require 'commandline_shared_examples.rb'


describe "The mzid_to_pepxml command" do

	describe ["mzid_to_pepxml.rb"] do
		it_behaves_like "a protk tool"
	end

end

