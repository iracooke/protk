require 'protk/prophet_tool'
require 'spec_helper'

describe ProphetTool do

  
  it "should correctly extract the database from an input file" do
    tool=ProphetTool.new
    dbname=tool.extract_db("#{$this_dir}/data/minimal_omssa.pep.xml")
    expect(dbname).to eq("/var/www/ISB/data/Databases/OnMascot//SPHuman/sphuman_20101013_DECOY.fasta")
  end
  
  it "should correctly extract the search engine name from an input file" do
    tool=ProphetTool.new
    dbname=tool.extract_engine("#{$this_dir}/data/minimal_omssa.pep.xml")
    expect(dbname).to eq("omssa")    
  end
    
end