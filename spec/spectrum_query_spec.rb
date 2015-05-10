require 'spec_helper'
require 'libxml'
require 'protk/spectrum_query'
require 'rspec/its'
require 'protk/mzidentml_doc'

include LibXML


def parse_spectrum_queries_from_mzid(mzid_file)
	MzIdentMLDoc.new(mzid_file).spectrum_queries
end

describe SpectrumQuery do 

	include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]

	let(:peptideshaker_mzid){
		xmlnodes = parse_spectrum_queries_from_mzid("#{@tmp_dir}/PeptideShaker_tiny.mzid")
		xmlnodes		
	}

	let(:query_from_mzid) {
		SpectrumQuery.from_mzid(peptideshaker_mzid[0])
	}

	describe "first query from mzid" do
		subject { query_from_mzid }
		it { should be_a SpectrumQuery }
		its(:spectrum_title) { should eq("Suresh Vp 1 to 10_BAF.3535.3535.1")}
		its(:retention_time) { should eq(6855.00001)}
		its(:psms) { should be_a Array }
		its(:psms) { should_not be_empty}

	end

	describe "converting to pepxml" do
		subject { query_from_mzid.as_protxml }
		it { should be_a XML::Node }
		it { should have_attribute_with_value("spectrum","Suresh Vp 1 to 10_BAF.3535.3535.1")}
		it { should have_attribute_with_value("retention_time","6855.00001")}
		its(:children) { should be_a Array }
		its(:children) { should_not be_empty }
	end

end