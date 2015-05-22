require 'spec_helper'
require 'libxml'
require 'protk/protein'
require 'protk/protein_group'
require 'rspec/its'
require 'protk/mzidentml_doc'

include LibXML

# RSpec::Matchers.define :be_an_array_of_protein_nodes  do
#   match do |nodes|

#     filename.chomp!
#     File.read(filename).include?('http://psidev.info/psi/pi/mzIdentML')
#   end
# end

describe ProteinGroup do 

	include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]

	let("mzid_doc"){
		MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
	}

	let(:peptideshaker_mzid){
		mzid_doc.protein_groups	
	}

	let(:basic_protein_group_from_mzid) {
		ProteinGroup.from_mzid(peptideshaker_mzid[0],mzid_doc)
	}

	let(:protxml_node) {
		ProteinGroup.from_mzid(peptideshaker_mzid[0],mzid_doc).as_protxml
	}	

	describe "first protein group from mzid" do
		subject { basic_protein_group_from_mzid }
		it { should be_a ProteinGroup}
		its(:group_number) {should eq(1)}
		its(:group_probability) { should eq(0.0)}
		its(:proteins) { should be_a Array }
	end

	describe "protein group to protxml" do
		subject { protxml_node }
		it { should be_a XML::Node }
		its(:children) { should be_a Array }
		its(:children) { should_not be_empty }
	end

end