require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The maker_to_proteindb command" do
	
	include_context :tmp_dir_with_fixtures,["maker_sample.gff"]

	let(:input_file) { "#{@tmp_dir}/maker_sample.gff" }
	let(:extra_args) { "" }

	describe ["maker_to_proteindb.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:validator) { have_lines_matching(8,"^>") }
		end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.fasta" }
			let(:validator) { have_lines_matching(8,"^>") }
		end
	end

end
