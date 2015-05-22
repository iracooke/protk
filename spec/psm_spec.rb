require 'spec_helper'
require 'libxml'
require 'protk/psm'
require 'rspec/its'
require 'protk/mzidentml_doc'

include LibXML

describe PeptideEvidence do
	include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]

	let(:mzid_doc){
		MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
	}

	let(:peptideshaker_mzid){
		# xmlnodes = parse_evidence_from_mzid("#{@tmp_dir}/PeptideShaker_tiny.mzid")
		xmlnodes = mzid_doc.peptide_evidence
		xmlnodes		
	}

	let(:first_pe_from_mzid) {
		PeptideEvidence.from_mzid(peptideshaker_mzid[0],mzid_doc)
	}

	describe "first pe from mzid" do
		subject { first_pe_from_mzid }
		it { should be_a PeptideEvidence }
		its(:protein){ should eq("JEMP01000193.1_rev_g3500.t1")}
		its(:peptide_prev_aa){ should eq("K")}
		its(:peptide_next_aa){ should eq("G")}

	end

	describe "converting to pepxml" do
		subject { first_pe_from_mzid.as_pepxml }
		it { should be_a XML::Node }		
		it { should have_attribute_with_value("protein","JEMP01000193.1_rev_g3500.t1")}
		it { should have_attribute_with_value("protein_descr","280755|283436")}
		it { should have_attribute_with_value("peptide_prev_aa","K")}
		it { should have_attribute_with_value("peptide_next_aa","G")}
	end

end

describe PSM do 

	include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]

	let(:mzid_doc){
		MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
	}

	let(:peptideshaker_mzid){
		xmlnodes = mzid_doc.psms
		xmlnodes		
	}

	let(:first_psm_from_mzid) {
		PSM.from_mzid(peptideshaker_mzid[0],mzid_doc)
	}

	describe "first psm from mzid" do
		subject { first_psm_from_mzid }
		it { should be_a PSM }
		its(:peptide) { should eq("KSPVYKVHFTR")}
		its(:calculated_mz){ should eq(1360.7615466836999) }
		its(:experimental_mz){ should eq(1362.805053710938) }
		its(:charge) { should eq(1)}

		its(:peptide_evidence) { should be_a Array}
		its(:peptide_evidence) { should_not be_empty}

	end

	describe "converting to pepxml" do
		subject { first_psm_from_mzid.as_pepxml.children.first }
		it { should be_a XML::Node }
		it { should have_attribute_with_value("peptide","KSPVYKVHFTR")}
		it { should have_attribute_with_value("protein","JEMP01000193.1_rev_g3500.t1")}
		it { should have_attribute_with_value("protein_descr","280755|283436")}
		it { should have_attribute_with_value("peptide_prev_aa","K")}
		it { should have_attribute_with_value("peptide_next_aa","G")}

		# its(:children) { should be_a Array }
		# its(:children) { should_not be_empty }
	end

end