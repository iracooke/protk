require 'spec_helper'
require 'libxml'
require 'protk/mzidentml_doc'
require 'protk/protein_summary'
require 'rspec/its'

include LibXML

describe ProteinSummary do 

  include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]


  let(:summary){
    ProteinSummary.from_mzid(MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid"))
  }

  it "can be initialized from mzid" do
    expect(summary).to be_a(ProteinSummary)
  end

  db = "/data/galaxy/galaxy/database/job_working_directory/"\
       "018/18515/PeptideShakerCLI/.PeptideShaker_unzip_temp/"\
       "peptideshaker_output_PeptideShaker_temp/data/input_database.fasta"

  describe "attributes from mzid" do
    subject{ summary }

    its(:reference_database) { should eq(db)}
    its(:residue_substitution_list) { should eq("")}
    its(:source_files) { should be_a Array }
    its(:source_files_alt) { should be_a Array }
    its(:sample_enzyme) { should eq("Trypsin")}
    its(:program_name) { should eq("PeptideShaker")}
    its(:program_version) { should eq("0.38.2")}
  end

  describe "as_protxml" do
    subject(:protxml_node) { summary.as_protxml }
    it "is an XML Node" do
      expect(protxml_node).to be_a(XML::Node)
    end
    it "is a protein_summary_header" do
      expect(protxml_node.name).to eq("protein_summary_header")
    end
    it "has a program_details node as its first child" do
      expect(protxml_node.children.length).to eq(1)
      expect(protxml_node.children.first.name).to eq("program_details")
    end



  end

end