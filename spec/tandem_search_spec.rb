require 'spec_helper'

describe "The xtandem_search command" do

	include_context :tmp_dir_with_files, ["tiny.mzML","testdb.fasta"]

	it "should run a search using absolute pathnames" do

		input_file="#{@tmp_dir}/tiny.mzML"
		db_file = "#{@tmp_dir}/testdb.fasta"

		output_file="#{@tmp_dir}/tiny_tandem.tandem"

		output_file.should_not exist?

		puts %x[tandem_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
		output_file.should be_a_non_empty_file
	end


	it "should run a search using relative pathnames" do
		Dir.chdir(@tmp_dir)
		# Get test input file/s
		input_file="tiny.mzML"
		db_file = "testdb.fasta"

		output_file="tiny_tandem.tandem"
		output_file.should_not exist?

		%x[tandem_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
		output_file.should be_a_non_empty_file
	end

end