require "protk/fastadb"

require 'spec_helper'

describe FastaDB do

  before :all do
  	@testdb = FastaDB.create("/tmp/testdb","spec/data/proteindb.fasta",'prot')
  	@testdb.should_not==nil
  end

  it "should correctly access a key by name" do
    query_id = "tr|O70238|O70238_MOUSE"
    item = @testdb.get_by_id(query_id)
    item.should be_instance_of(Bio::FastaFormat)
    item.entry_id.should eq query_id
    item.length.should eq 227
  end

end