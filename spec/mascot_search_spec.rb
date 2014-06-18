require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The mascot_searc tool" do

	describe ["mascot_search.rb"] do
		it_behaves_like "a protk tool"
	end

end