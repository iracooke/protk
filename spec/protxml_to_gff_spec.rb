require 'spec_helper'
require 'commandline_shared_examples.rb'

def blast_installed
  env=Constants.new
  env.makeblastdb.length>0
end



describe "The protxml_to_gff command" do

	include_context :tmp_dir_with_fixtures, [
		"small.prot.xml",
		"small_combined.gff",
		"small_prot.fasta"]

	let(:extra_args) { " -d #{@tmp_dir}/small_prot.fasta -c #{@tmp_dir}/small_combined.gff --gff-idregex='lcl\\|([^ ]*)'"}
	let(:input_file ) { "#{@tmp_dir}/small.prot.xml" }
	let(:output_ext) {".gff"}
	let(:suffix) {""}
	let(:tmp_dir) {@tmp_dir}

	describe ["protxml_to_gff.rb"] , :dependencies_installed=>blast_installed do
		it_behaves_like "a protk tool"
	    it_behaves_like "a protk tool that defaults to stdout" do
	    	
      		let(:validator) { have_lines_matching(17,"polypeptide") }
    	end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.gff" }
			let(:validator) { have_lines_matching(17,"polypeptide") }
		end

	end

end