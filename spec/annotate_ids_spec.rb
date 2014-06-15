require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "the annotate_ids command" do 

	describe ["annotate_ids.rb"] do
		it_behaves_like "a protk tool"
	end

end