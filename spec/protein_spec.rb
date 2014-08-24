require 'spec_helper'
require 'libxml'
require 'protk/protein'
require 'rspec/its'

include LibXML


def parse_proteins(protxml_file)
  protxml_parser=XML::Parser.file(protxml_file)
  protxml_doc=protxml_parser.parse
  proteins = protxml_doc.find('.//protxml:protein','protxml:http://regis-web.systemsbiology.net/protXML')
  proteins
end

describe Protein do 

	include_context :tmp_dir_with_fixtures, ["test.protXML"]

	let(:first_protein) { 
		xmlnodes = parse_proteins("#{@tmp_dir}/test.protXML")
		Protein.from_protxml(xmlnodes[0])
	}

	describe "first protein" do
		subject { first_protein }
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
		peps = first_protein.peptides
		expect(peps[0]).to be_a Peptide
	end


end