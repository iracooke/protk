require 'spec_helper'
require 'protk/sniffer'


describe Sniffer do

  include_context :tmp_dir_with_fixtures, [
    "tiny.mzML",
    "tiny.mgf"]

	let(:mzml_file) { "#{@tmp_dir}/tiny.mzML" }
	let(:mgf_file) { "#{@tmp_dir}/tiny.mgf" }

    it "should detect mzml" do
    	expect(Sniffer.sniff_format(mzml_file)).to eq("mzML")
    end

    it "should detect mgf" do
    	expect(Sniffer.sniff_format(mgf_file)).to eq("mgf")
    end

end