require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The augustus_to_proteindb command" do

	describe ["augustus_to_proteindb.rb"] do
		it_behaves_like "a protk tool"
	end

	describe "running the tool" do
		include_context :tmp_dir_with_fixtures,["augustus_sample.gff"]

		before(:each) do
			@input_file="#{@tmp_dir}/augustus_sample.gff"
			@output_file="#{@tmp_dir}/output.fasta"
		end

		it "sends output to stdout by default" do
			%x[augustus_to_proteindb.rb #{@input_file} > #{@output_file}]
			expect(@output_file).to exist?			
		end

		it "sends output to a file when asked" do
			%x[augustus_to_proteindb.rb #{@input_file} -o #{@output_file}]
			expect(@output_file).to exist?			
		end

	end
end