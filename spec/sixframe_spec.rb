require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The sixframe command" do

	include_context :tmp_dir_with_fixtures, ["small_genome.fasta"]

	let(:extra_args) { "" }
	let(:input_file ) { "#{@tmp_dir}/small_genome.fasta" }

	describe ["sixframe.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:validator) { have_lines_matching(17970,"^>") }
		end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.fasta" }
			let(:validator) { have_lines_matching(17970,"^>") }
		end

	end

end