require 'spec_helper'
require 'libxml'
require 'protk/mzidentml_doc'
require 'rspec/its'

include LibXML

describe MzIdentMLDoc do 

  include_context :tmp_dir_with_fixtures, ["PeptideShaker_tiny.mzid"]


  describe "peptideshaker_tiny.mzid" do

    let(:doc){
      MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
    }

    it "has one search database" do
      expect( doc.search_databases.length ).to eq(1)
    end

    it "has four source files" do
      expect( doc.source_files.length ).to eq(4)
    end

    it "has one enzyme" do
      expect( doc.enzymes.length ).to eq(1)
    end

    it "has one analysis software" do
      expect( doc.analysis_software.length ).to eq(1)
    end

    it "has two protein groups" do
      expect(doc.protein_groups.length).to eq(2)
    end

    describe "protein group caching" do

      let(:group_node0) { doc.protein_groups[0] }
      let(:group_node1) { doc.protein_groups[1] }

      it "works for two different nodes" do
        protein_nodes0=doc.get_proteins_for_group(group_node0)
        protein_nodes1=doc.get_proteins_for_group(group_node1)

        expect(protein_nodes0[0].attributes['id']).to eq("PAG_0_1")
        expect(protein_nodes1[0].attributes['id']).to eq("PAG_4_1")        

      end

    end

  end

end