require "protk/gffdb"
require "protk/constants"

require 'spec_helper'


describe GFFDB do 

  include_context :tmp_dir_with_fixtures, ["transdecoder_gff.gff3"]

  let(:testdb) { GFFDB.create("#{@tmp_dir}/transdecoder_gff.gff3") }

  it "should instantiate correctly" do
    expect(testdb).to be_instance_of(GFFDB)
  end

  it "should correctly access a key by name" do
    query_id = "comp1000018_c0_seq1|g.205055"
    item = testdb.get_by_id(query_id)
    expect(item).to be_instance_of(Array)
    expect(item.first).to be_instance_of(Bio::GFF::GFF3::Record)
  end

end