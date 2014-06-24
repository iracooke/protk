require 'spec_helper'
require 'commandline_shared_examples.rb'

def tandem_installed
	installed=(%x[which tandem].length>0)
	installed=(%x[which tandem.exe].length>0) unless installed
	installed
end

describe "The xtandem_search command", :broken => false do

	include_context :tmp_dir_with_fixtures, ["tiny.mzML","testdb.fasta"]


	let(:input_file) { "#{@tmp_dir}/tiny.mzML" }
	let(:db_file) { "#{@tmp_dir}/testdb.fasta" }
	let(:extra_args) {"-d #{db_file}"}
	let(:suffix) { "_tandem"}
	let(:output_ext) {".tandem"}

	describe ["tandem_search.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["tandem_search.rb"] , :dependencies_installed => tandem_installed do
		it_behaves_like "a protk tool"
		it_behaves_like "a protk tool with default file output", :dependencies_installed => tandem_installed		
		it_behaves_like "a protk tool that supports explicit output",:dependencies_installed => tandem_installed do
			let(:output_file) { "#{@tmp_dir}/out.tandem" }
			let(:validator) { have_lines_matching(26,"protein") }
		end


		it "should output spectra when requested" do
			output_file="#{@tmp_dir}/tmp.tandem"
			%x[tandem_search.rb -d #{db_file} #{input_file} -o #{output_file} --output-spectra]
			expect(output_file).to contain_text("type=\"tandem mass spectrum\"")	
		end

	end




end

