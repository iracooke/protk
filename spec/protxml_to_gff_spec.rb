require 'spec_helper'
require 'commandline_shared_examples.rb'

def blast_installed
  env=Constants.new
  env.makeblastdb.length>0
end



describe "The protxml_to_gff command" do

	include_context :tmp_dir_with_fixtures, [
		"small.prot.xml",
		"small_genome.fasta",
		"small_prot.fasta"]

	let(:extra_args) { " -d #{@tmp_dir}/small_prot.fasta -g #{@tmp_dir}/small_genome.fasta" }
	let(:input_file ) { "#{@tmp_dir}/small.prot.xml" }
	let(:output_ext) {".gff"}
	let(:suffix) {""}

	describe ["protxml_to_gff.rb"] , :dependencies_installed=>blast_installed do
		it_behaves_like "a protk tool"
	    it_behaves_like "a protk tool with default file output" do
	    	
      		let(:validator) { have_lines_matching(4,"protein") }
      		let(:validator1) { have_lines_matching(13,"peptide") }
    	end

		it_behaves_like "a protk tool that supports explicit output" do
			let(:output_file) { "#{@tmp_dir}/out.gff" }
			let(:validator) { have_lines_matching(4,"protein") }
      		let(:validator1) { have_lines_matching(13,"peptide") }
		end

	end

end