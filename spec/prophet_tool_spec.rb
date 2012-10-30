# Unit tests for the ProphetTool class
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../")

require 'prophet_tool'


describe ProphetTool do

  
  it "should correctly extract the database from an input file" do
    tool=ProphetTool.new
    dbname=tool.extract_db("data/minimal_omssa.pep.xml")
    dbname.should=="/var/www/ISB/data/Databases/OnMascot//SPHuman/sphuman_20101013_DECOY.fasta"
  end
  
  it "should correctly extract the search engine name from an input file" do
    tool=ProphetTool.new
    dbname=tool.extract_engine("data/minimal_omssa.pep.xml")
    dbname.should=="omssa"    
  end
    
end