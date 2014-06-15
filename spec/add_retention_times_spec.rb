require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The add_retention_times command" do

	describe ["add_retention_times.rb"] do
		it_behaves_like "a protk tool"
	end

	describe "Running with sample data" do

		include_context :tmp_dir_with_fixtures, ["test.protXML","tiny.mgf"]
		 # TODO Generate some sample data for this tool

	end

end