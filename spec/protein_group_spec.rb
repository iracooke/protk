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

	include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid","UF_DIA_Good.mzid"]

	describe "PeptideShaker_tiny.mzid" do
		let("mzid_doc"){
			MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
		}

		let(:peptideshaker_mzid){
			mzid_doc.protein_groups	
		}

		describe "first protein group from mzid" do
			subject{ ProteinGroup.from_mzid(peptideshaker_mzid[0],mzid_doc) }

			it { should be_a ProteinGroup}
			its(:group_number) {should eq(1)}
			its(:group_probability) { should eq(0.0)}
			its(:proteins) { should be_a Array }
		end

		describe "second protein group" do
			subject(:protein_group){ ProteinGroup.from_mzid(peptideshaker_mzid[1],mzid_doc) }

			it { should be_a ProteinGroup}
			its(:group_number) {should eq(5)}
			its(:group_probability) { should eq(100.0)}
			its(:proteins) { should be_a Array }

			describe "as_protxml" do
				subject(:as_protxml){ protein_group.as_protxml }	

				it { should be_a XML::Node }
				it "should have 1 protein" do
					expect(as_protxml.children.length).to eq(1)
				end
				it "it should have the correct attributes" do
					expect(as_protxml.attributes['group_number']).to eq("5")
					expect(as_protxml.attributes['group_probability']).to eq("1.0")
				end

				describe "child protein" do
					let(:protein){ as_protxml.children[0] }
					it "should have the correct name" do
						expect(protein.attributes['protein_name']).to eq("JEMP01000061.1_rev_g10170.t1")
					end
				end
			end
		end
	end
end		


		# describe "UF_DIA_Good.mzid" do
		# 	let("mzid_doc"){
		# 		MzIdentMLDoc.new("#{@tmp_dir}/UF_DIA_Good.mzid")
		# 	}

		# let(:peptideshaker_mzid){
		# 	mzid_doc.protein_groups	
		# }

		# describe "first protein group from mzid" do
		# 	subject{ ProteinGroup.from_mzid(peptideshaker_mzid[0],mzid_doc) }

		# 	it { should be_a ProteinGroup}
		# 	its(:group_number) {should eq(1)}
		# 	its(:group_probability) { should eq(0.0)}
		# 	its(:proteins) { should be_a Array }
		# end

		# describe "second protein group" do
		# 	subject(:protein_group){ ProteinGroup.from_mzid(peptideshaker_mzid[1],mzid_doc) }

		# 	it { should be_a ProteinGroup}
		# 	its(:group_number) {should eq(5)}
		# 	its(:group_probability) { should eq(100.0)}
		# 	its(:proteins) { should be_a Array }

		# 	describe "as_protxml" do
		# 		subject(:as_protxml){ protein_group.as_protxml }	

		# 		it { should be_a XML::Node }
		# 		it "should have 1 protein" do
		# 			expect(as_protxml.children.length).to eq(1)
		# 		end
		# 		it "it should have the correct attributes" do
		# 			expect(as_protxml.attributes['group_number']).to eq("5")
		# 			expect(as_protxml.attributes['group_probability']).to eq("100.0")
		# 		end

		# 		describe "child protein" do
		# 			let(:protein){ as_protxml.children[0] }
		# 			it "should have the correct name" do
		# 				expect(protein.attributes['protein_name']).to eq("JEMP01000061.1_rev_g10170.t1")
		# 			end

		# 		end

		# 		# its(:children) { should be_a Array }
		# 		# its(:children) { should_not be_empty }


			# end
		# end

		# end
	# end


# end