require 'spec_helper'
require 'commandline_shared_examples.rb'

def sphuman_not_installed
	res=%x[ls ~/.protk/Databases/sphuman/current.fasta]
	$?.exitstatus>0
end

describe "The mascot_to_pepxml tool" do

	describe ["mascot_to_pepxml.rb"] do
		it_behaves_like "a protk tool"
	end


	describe "Running with sample data",:broken => true, :dependencies_not_installed => sphuman_not_installed do

		include_context :tmp_dir_with_fixtures, ["tinymgfresults.mascotdat"]


		before(:each) do
			@input_file="#{@tmp_dir}/tinymgfresults.mascotdat"
			@output_file="#{@tmp_dir}/output.fasta"
			@num_entries_in_test=4
		end

		it "-o option works" do
			puts %x[mascot_to_pepxml.rb #{@input_file} -o #{@output_file}]
			expect(@output_file).to exist?
		end

	end

end