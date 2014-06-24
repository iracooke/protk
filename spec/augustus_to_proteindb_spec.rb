require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The augustus_to_proteindb command" do
	
	include_context :tmp_dir_with_fixtures,["augustus_sample.gff"]

	let(:input_file) { "#{@tmp_dir}/augustus_sample.gff" }
	let(:extra_args) { "" }

	describe ["augustus_to_proteindb.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:validator) { have_lines_matching(12,"^>") }
		end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.fasta" }
			let(:validator) { have_lines_matching(12,"^>") }
		end
	end

end