require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The add_retention_times command" do

	describe ["add_retention_times.rb"] do
		it_behaves_like "a protk tool"
	end

end