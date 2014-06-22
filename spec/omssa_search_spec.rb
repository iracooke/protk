require 'spec_helper'
require 'commandline_shared_examples.rb'

def omssa_not_installed
	installed=(%x[which omssacl].length>0)
	!installed
end

describe "The omssa_search command", :broken => false do

	include_context :tmp_dir_with_fixtures, ["mr176-BSA100fmole_BA3_01_8168.d.mgf","AASequences.fasta"]

	before(:each) do
		@input_file="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d.mgf"
	    @db_file = "#{@tmp_dir}/AASequences.fasta"
    	@output_file="#{@tmp_dir}/tiny_omssa.pepXML"
		@extra_args="-d #{@db_file} --max-hit-expect 1000"    	
	end


	describe ["omssa_search.rb",".pep.xml","_omssa"] do
		it_behaves_like "a protk tool"
		it_behaves_like "a protk tool with default file output"		
	end

	it "should run a search using absolute pathnames", :dependencies_not_installed => omssa_not_installed do

		%x[omssa_search.rb #{@extra_args} #{@input_file} -o #{@output_file}]
		
		expect(@output_file).to exist?			
	end


	it "should run a search using relative pathnames", :dependencies_not_installed => omssa_not_installed do

		Dir.chdir(@tmp_dir) do
			input_file="mr176-BSA100fmole_BA3_01_8168.d.mgf"
			db_file = "AASequences.fasta"

			output_file="tiny_omssa.omssa"
			expect(output_file).not_to exist?

			%x[omssa_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
			expect(output_file).to exist?	
		end
	end


end

