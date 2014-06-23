require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The pepxml_to_table command", :broken => false do

	include_context :tmp_dir_with_fixtures, [
		"mr176-BSA100fmole_BA3_01_8167.d_msgfplus.pep.xml",
		"mr176-BSA100fmole_BA3_01_8167.d_omssa.pep.xml",
		"mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"]

	before(:each) do
		@msgfplus_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_msgfplus.pep.xml"
		@omssa_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_omssa.pep.xml"
		@tandem_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"

    	@output_file="#{@tmp_dir}/out.txt"
	end

	describe ["pepxml_to_table.rb"] do
		it_behaves_like "a protk tool"

		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { @omssa_pepxml }
			let(:match_requirement) { ["OMSSA",2] }
		end
		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { @tandem_pepxml }
			let(:match_requirement) { ["X! Tandem",91] }
		end
		it_behaves_like "a protk tool that defaults to stdout" do
			let(:input_file) { @msgfplus_pepxml }
			let(:match_requirement) { ["MS-GF",70] }
		end
	end

	# it "should run a search using absolute pathnames", :dependencies_not_installed => tandem_not_installed do
		
	# 	%x[tandem_search.rb -d #{@db_file} #{@input_file} -o #{@output_file}]
		
	# 	expect(@output_file).to exist?
	# 	expect(@output_file).not_to contain_text("default from tandem_search.rb")
	# end


	# it "should run a search using relative pathnames", :dependencies_not_installed => tandem_not_installed do

	# 	Dir.chdir("#{@tmp_dir}") do
	# 		input_file="tiny.mzML"
	# 		db_file = "testdb.fasta"

	# 		output_file="tiny_tandem.tandem"
	# 		expect(output_file).not_to exist?

	# 		%x[tandem_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
	# 		expect(output_file).to exist?
	# 	end
	# end

	# it "should output spectra when requested" , :dependencies_not_installed => tandem_not_installed do

	# 	%x[tandem_search.rb -d #{@db_file} #{@input_file} -o #{@output_file} --output-spectra]
	# 	expect(@output_file).to contain_text("type=\"tandem mass spectrum\"")
	
	# end


end

