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

  end

end