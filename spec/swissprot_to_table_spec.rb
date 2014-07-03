require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The swissprot_to_table command", :broken => false do

	include_context :tmp_dir_with_fixtures, [
		"AugustUniprot.dat",
		"protein_query_list.txt"]

	let(:db_file) { "#{@tmp_dir}/AugustUniprot.dat" }
	let(:input_file) { "#{@tmp_dir}/protein_query_list.txt" }
	let(:extra_args) { "-d #{db_file}" }

	describe ["swissprot_to_table.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:validator) { have_lines_matching(8,"GO:0046872") }
		end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.txt" }
			let(:validator) { have_lines_matching(8,"GO:0046872") }
		end

	end

end