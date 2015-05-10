require 'spec_helper'
require 'libxml'
require 'protk/psm'
require 'rspec/its'
require 'protk/mzidentml_doc'

include LibXML


def parse_psms_from_mzid(mzid_file)
	MzIdentMLDoc.new(mzid_file).psms
end

describe PSM do 

	include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]

	let(:peptideshaker_mzid){
		xmlnodes = parse_psms_from_mzid("#{@tmp_dir}/PeptideShaker_tiny.mzid")
		xmlnodes		
	}

	let(:psm_from_mzid) {
		PSM.from_mzid(peptideshaker_mzid[0])
	}

	describe "first psm from mzid" do
		subject { psm_from_mzid }
		it { should be_a PSM }
		its(:peptide) { should eq("KSPVYKVHFTR")}
		its(:primary_protein) { should eq("JEMP01000193.1_rev_g3500.t1")}
		its(:num_tot_proteins) {should eq(1)}

	end

	describe "converting to pepxml" do
		subject { psm_from_mzid.as_protxml }
		it { should be_a XML::Node }
		# it { should have_attribute_with_value("spectrum","Suresh Vp 1 to 10_BAF.3535.3535.1")}
		# it { should have_attribute_with_value("retention_time","6855.00001")}
		# its(:children) { should be_a Array }
		# its(:children) { should_not be_empty }
	end

end