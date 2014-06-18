require "protk/fastadb"
require "protk/constants"

require 'spec_helper'

def blast_not_installed
  env=Constants.new
  env.makeblastdb.length==0
end

describe FastaDB , :dependencies_not_installed => blast_not_installed do 

  include_context :tmp_dir_with_fixtures, ["proteindb.fasta"]

  before :each do
  	@testdb = FastaDB.create("#{@tmp_dir}/testdb","#{@tmp_dir}/proteindb.fasta",'prot')
  	expect(@testdb).to be_instance_of(FastaDB)
  end



  it "should correctly access a key by name" do
    query_id = "tr|O70238|O70238_MOUSE"
    item = @testdb.get_by_id(query_id)
    expect(item).to be_instance_of(Bio::FastaFormat)
    expect(item.entry_id).to eq(query_id)
    expect(item.length).to eq(227)
  end

end