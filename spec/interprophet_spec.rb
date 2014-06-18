require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The interprophet tool" do

	describe ["interprophet.rb"] do
		it_behaves_like "a protk tool"
	end

	describe "Running with sample data" do

		include_context :tmp_dir_with_fixtures, ["test.protXML","tiny.mgf"]
		 # TODO Generate some sample data for this tool

	end
end