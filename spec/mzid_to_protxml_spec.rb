require 'spec_helper'
require 'commandline_shared_examples.rb'


describe "The mzid_to_protxml command" do

	describe ["mzid_to_protxml.rb"] do
		it_behaves_like "a protk tool"
	end

end

