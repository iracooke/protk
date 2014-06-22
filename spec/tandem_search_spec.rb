require 'spec_helper'
require 'commandline_shared_examples.rb'

def tandem_not_installed
	installed=(%x[which tandem].length>0)
	installed=(%x[which tandem.exe].length>0) unless installed
	!installed
end

describe "The xtandem_search command", :broken => false do

	include_context :tmp_dir_with_fixtures, ["tiny.mzML","testdb.fasta"]

	before(:each) do
		@input_file="#{@tmp_dir}/tiny.mzML"
	    @db_file = "#{@tmp_dir}/testdb.fasta"
    	@output_file="#{@tmp_dir}/tinytandem.tandem"
		@extra_args="-d #{@db_file}"
	end

	describe ["tandem_search.rb",".tandem","_tandem"] do
		it_behaves_like "a protk tool"
		it_behaves_like "a protk tool with default file output"
	end

	it "should run a search using absolute pathnames", :dependencies_not_installed => tandem_not_installed do
		
		%x[tandem_search.rb -d #{@db_file} #{@input_file} -o #{@output_file}]
		
		expect(@output_file).to exist?
		expect(@output_file).not_to contain_text("default from tandem_search.rb")
	end


	it "should run a search using relative pathnames", :dependencies_not_installed => tandem_not_installed do

		Dir.chdir("#{@tmp_dir}") do
			input_file="tiny.mzML"
			db_file = "testdb.fasta"

			output_file="tiny_tandem.tandem"
			expect(output_file).not_to exist?

			%x[tandem_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
			expect(output_file).to exist?
		end
	end

	it "should output spectra when requested" , :dependencies_not_installed => tandem_not_installed do

		%x[tandem_search.rb -d #{@db_file} #{@input_file} -o #{@output_file} --output-spectra]
		expect(@output_file).to contain_text("type=\"tandem mass spectrum\"")
	
	end


end

