require "protk/gffdb"
require "protk/constants"

require 'spec_helper'


describe GFFDB do 

  include_context :tmp_dir_with_fixtures, ["transdecoder_gff.gff3","augustus_sample.gff"]

  let(:testdb) { GFFDB.create("#{@tmp_dir}/transdecoder_gff.gff3") }

  let(:augustus_testdb) { GFFDB.create("#{@tmp_dir}/augustus_sample.gff") }

  describe "transdecoder gff" do
    it "should instantiate correctly" do
      expect(testdb).to be_instance_of(GFFDB)
    end

    it "should correctly access a key by id" do
      query_id = "comp1000018_c0_seq1|g.205055"
      item = testdb.get_by_id(query_id)
      expect(item.first).to be_instance_of(Bio::GFF::GFF3::Record)
    end

    it "should have a valid parent to cds mapping" do
      query_id = "comp1000018_c0_seq1|m.205055"
      item = testdb.get_cds_by_parent_id(query_id)
      expect(item).to be_a(Array)
      expect(item.first).to be_a(Bio::GFF::GFF3::Record)
    end
  end

  describe "augustus gff" do

    it "should instantitate correctly" do
      expect(augustus_testdb).to be_instance_of(GFFDB)
    end

    it "should correctly access a key by id" do
      query_id = "g4.t1.cds"
      item = augustus_testdb.get_by_id(query_id)
      expect(item).to be_instance_of(Array)
      expect(item.length).to eq(3)
      expect(item.first).to be_instance_of(Bio::GFF::GFF3::Record)
    end

    it "should have a valid parent to cds mapping" do
      query_id = "g4.t1"
      item = augustus_testdb.get_cds_by_parent_id(query_id)
      expect(item).to be_a(Array)
      expect(item.length).to eq(3)
      expect(item.first).to be_a(Bio::GFF::GFF3::Record)
    end



  end

end