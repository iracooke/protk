require 'spec_helper'
require 'commandline_shared_examples.rb'


RSpec.shared_context :tiny_inputs_and_outputs do 

  before(:each) do
    @tmp_dir=Dir.mktmpdir

    ["tiny.mzML","testdb.fasta"].each do |file| 
      file_path=Pathname.new("#{$this_dir}/data/#{file}").realpath.to_s
      throw "test file #{file} does not exist" unless File.exist? file_path
      File.symlink(file_path,"#{@tmp_dir}/#{file}")
    end

    @tiny_input="#{@tmp_dir}/tiny.mzML"
    @db_file = "#{@tmp_dir}/testdb.fasta"
    @output_file="#{@tmp_dir}/tiny_tandem.tandem"

  end

end

def tandem_not_installed
	installed=(%x[which tandem].length>0)
	installed=(%x[which tandem.exe].length>0) unless installed
	!installed
end

describe "The xtandem_search command", :broken => false do

	include_context :tiny_inputs_and_outputs

	describe ["tandem_search.rb"] do
		it_behaves_like "a protk tool"
	end

	it "should run a search using absolute pathnames", :dependencies_not_installed => tandem_not_installed do

		%x[tandem_search.rb -d #{@db_file} #{@tiny_input} -o #{@output_file}]
		
		expect(@output_file).to exist?
		expect(@output_file).not_to contain_text("default from tandem_search.rb")
	end


	it "should run a search using relative pathnames", :dependencies_not_installed => tandem_not_installed do

		Dir.chdir(@tmp_dir)
		input_file="tiny.mzML"
		db_file = "testdb.fasta"

		output_file="tiny_tandem.tandem"
		expect(output_file).not_to exist?

		%x[export PATH=#{@mocks_path}:$PATH; tandem_search.rb -d #{db_file} #{input_file} -o #{output_file}]
		
		expect(output_file).to exist?
		expect(output_file).not_to contain_text("default from tandem_search.rb")		
	end


	it "should output spectra when requested" , :dependencies_not_installed => tandem_not_installed do

		%x[tandem_search.rb -d #{@db_file} #{@tiny_input} -o #{@output_file} --output-spectra]
		expect(@output_file).to contain_text("type=\"tandem mass spectrum\"")
	
	end


end

