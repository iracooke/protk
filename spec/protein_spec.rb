require 'spec_helper'
require 'libxml'
require 'protk/protein'
require 'rspec/its'
require 'protk/mzidentml_doc'

include LibXML


def parse_proteins(protxml_file)
  protxml_parser=XML::Parser.file(protxml_file)
  protxml_doc=protxml_parser.parse
  proteins = protxml_doc.find('.//protxml:protein','protxml:http://regis-web.systemsbiology.net/protXML')
  proteins
end

describe Protein do 

	include_context :tmp_dir_with_fixtures, ["test.protXML","small.prot.xml","PeptideShaker_tiny.mzid"]

	let(:test_protxml){
		xmlnodes = parse_proteins("#{@tmp_dir}/test.protXML")
		xmlnodes		
	}

	let(:small_protxml){
		xmlnodes = parse_proteins("#{@tmp_dir}/small.prot.xml")
		xmlnodes		
	}

	let(:peptideshaker_mzid){
		xmlnodes = parse_proteins_from_mzid("#{@tmp_dir}/PeptideShaker_tiny.mzid")
		xmlnodes		
	}

	let(:mzid_doc){
		MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
	}

	let(:basic_protein_from_mzid) {
		Protein.from_mzid(mzid_doc.proteins[0],mzid_doc)
	}

	let(:basic_protein) { 
		Protein.from_protxml(test_protxml[0])
	}




	describe "first protein from mzid" do
		subject { basic_protein_from_mzid }
		it { should be_a Protein}
		its(:group_number) {should eq(1)}
		its(:group_probability) { should eq(0.0)}
		its(:probability) { should eq(0.00)}
		its(:protein_name) { should eq("JEMP01000193.1_rev_g3500.t1") }
		its(:n_indistinguishable_proteins) { should eq(1)}
		its(:percent_coverage) { should eq(0.0)}
		its(:peptides) { should be_a Array }

	end

	describe "converting to protxml" do
		subject { basic_protein_from_mzid.as_protxml }
		it { should be_a XML::Node }
		it { should have_attribute_with_value("protein_name","JEMP01000193.1_rev_g3500.t1")}
		it { should have_attribute_with_value("n_indistinguishable_proteins","1")}
		it { should have_attribute_with_value("probability","0.0")}
		it { should have_attribute_with_value("percent_coverage","0.0")}
		it { should have_attribute_with_value("unique_stripped_peptides","KSPVYKVHFTR")}
		it { should have_attribute_with_value("total_number_peptides","1")}
		its(:children) { should be_a Array }
		its(:children) { should_not be_empty }
	end

	describe "first protein" do
		subject { basic_protein }
		it { should be_a Protein}
		its(:group_number) {should eq(1)}
		its(:group_probability) { should eq(1.00)}
		its(:probability) { should eq(1.00)}
		its(:protein_name) { should eq("ACADV_MOUSE") }
		its(:n_indistinguishable_proteins) { should eq(1)}
		its(:percent_coverage) { should eq(9.9)}
		its(:peptides) { should be_a Array }

	end
	
	it "should should have valid peptides" do
		peps = basic_protein.peptides
		expect(peps[0]).to be_a Peptide
	end


	# <protein_group group_number="7" probability="1.0000">
	#       <protein protein_name="lcl|scaffold10_fwd_g447.t1" n_indistinguishable_proteins="1" probability="1.0000" percent_coverage="5.0" unique_stripped_peptides="LVPISDEELDPLTALPVYSR" group_sibling_id="a" total_number_peptides="2" pct_spectrum_ids="0.006" confidence="0.007">
	#          <parameter name="prot_length" value="402"/>
	#          <annotation protein_description="195564 196835"/>
	#          <peptide peptide_sequence="LVPISDEELDPLTALPVYSR" charge="2" initial_probability="0.9990" nsp_adjusted_probability="0.9996" peptide_group_designator="a" weight="1.00" group_weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="0.75" n_sibling_peptides_bin="2" n_instances="1" exp_tot_instances="1.00" is_contributing_evidence="Y" calc_neutral_pep_mass="2226.1793">
	#          </peptide>
	#          <peptide peptide_sequence="LVPISDEELDPLTALPVYSR" charge="3" initial_probability="0.7530" nsp_adjusted_probability="0.8805" peptide_group_designator="a" weight="1.00" group_weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="1.00" n_sibling_peptides_bin="2" n_instances="1" exp_tot_instances="0.75" is_contributing_evidence="Y" calc_neutral_pep_mass="2226.1798">
	#          </peptide>
	#       </protein>
	# </protein_group>

	let(:protein_with_multiple_charge_state_peptides){
		Protein.from_protxml(small_protxml[1])
	}

	it "should correctly collapse multiply charged peptides when asked" do
		all_peptides = protein_with_multiple_charge_state_peptides.peptides
		unique_peptides = protein_with_multiple_charge_state_peptides.representative_peptides()
		expect(all_peptides.length).to eq(2)
		expect(unique_peptides.length).to eq(1)
	end


end