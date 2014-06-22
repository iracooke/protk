require 'spec_helper'
require 'commandline_shared_examples.rb'

def msgfplus_not_installed
	installed=(%x[which MSGFPlus.jar].length>0)
	!installed
end

describe "The msgfplus_search command", :broken => false do

	include_context :tmp_dir_with_fixtures, ["tiny.mzML","testdb.fasta"]

	before(:each) do
		@input_file="#{@tmp_dir}/tiny.mzML"
	    @db_file = "#{@tmp_dir}/testdb.fasta"
    	@output_file="#{@tmp_dir}/tiny_msgfplus.pepXML"
		@extra_args="-d #{@db_file} -p 200"    	
	end


	describe ["msgfplus_search.rb"] do
		it_behaves_like "a protk tool"
	end

	describe ["msgfplus_search.rb",".mzid","_msgfplus"], :dependencies_not_installed => msgfplus_not_installed do
		it_behaves_like "a protk tool with default file output"		
	end

	it "should run a search using absolute pathnames", :dependencies_not_installed => msgfplus_not_installed do

		%x[msgfplus_search.rb #{@extra_args} #{@input_file} -o #{@output_file}]
		
		expect(@output_file).to exist?
		expect(@output_file).to be_mzidentml		
	end


	it "should run a search using relative pathnames",:broken=>true, :dependencies_not_installed => msgfplus_not_installed do

		Dir.chdir(@tmp_dir) do
			input_file=Pathname.new(@input_file).basename.to_s
			db_file = Pathname.new(@db_file).basename.to_s

			output_file="tiny_msgfplus.mzid"
			expect(output_file).not_to exist?

			%x[msgfplus_search.rb -d #{db_file} -p 200 #{input_file} -o #{output_file}]
			
			expect(output_file).to exist?	
		end
	end

	it "should support the --pepxml option", :dependencies_not_installed => msgfplus_not_installed do

		%x[msgfplus_search.rb #{@extra_args} #{@input_file} -o #{@output_file} --pepxml]
		
		expect(@output_file).to exist?
		expect(@output_file).to be_pepxml		
		expect(@output_file).to have_pepxml_hits_matching(2,/BOVIN/)
	end


end

