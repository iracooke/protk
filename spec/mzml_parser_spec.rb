
require 'protk/mzml_parser'
require 'spec_helper'


describe MzMLParser do

	include_context :tmp_dir_with_fixtures, ["tiny.mzML"]

	before(:each) do
		@parser=MzMLParser.new("#{@tmp_dir}/tiny.mzML")
	end

	it "can be instantiated" do
		expect(@parser).to be_a(MzMLParser)
	end	

	it "can return spectra one by one" do
		first = @parser.next_spectrum
		second = @parser.next_spectrum

		expect(first).not_to eq(second)
	end

	it "can convert a spectrum to a dictionary" do
		spec = @parser.next_spectrum()
		puts spec
		expect(spec).to be_a(Hash)
		expect(spec[:mzlevel]).to eq("1")
		expect(spec[:mz]).not_to eq(spec[:intensity])
		expect(spec[:index].to_i).to eq(0)
		expect(spec[:id]).to eq("scan=1")
	end

	it "returns nil when at the end of a file" do
		i=0
		max_entries_in_test_file=10
		while ( @parser.next_spectrum && (i < max_entries_in_test_file)) do
			i+=1
		end
		expect(i).to be < max_entries_in_test_file

	end

end