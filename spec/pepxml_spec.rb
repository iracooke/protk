require 'spec_helper'
require 'protk/pepxml'
require 'tempfile'


describe PepXML do

  include_context :tmp_dir_with_fixtures, [
    "mr176-BSA100fmole_BA3_01_8167.d_msgfplus.pep.xml",
    "mr176-BSA100fmole_BA3_01_8167.d_omssa.pep.xml",
    "mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"]

  before(:each) do
    @msgfplus_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_msgfplus.pep.xml"
    @omssa_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_omssa.pep.xml"
    @tandem_pepxml="#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem.pep.xml"
  end

  it "finds runs on msgfplus pepXML" do
    pepxml = PepXML.new(@msgfplus_pepxml)
    pruns = pepxml.find_runs()
    expect(pruns["mr176-BSA100fmole_BA3_01_8167.d"][:type]).to eq("mzML")
  end

  it "finds runs on omssa pepXML" do
    pepxml = PepXML.new(@omssa_pepxml)
    pruns = pepxml.find_runs()
    expect(pruns["mr176-BSA100fmole_BA3_01_8167.d.mgf"][:type]).to eq("mgf")
  end

  it "finds runs on tandem pepXML" do
    pepxml = PepXML.new(@tandem_pepxml)
    pruns = pepxml.find_runs()
    expect(pruns["mr176-BSA100fmole_BA3_01_8167.d_tandem.tandem"][:type]).to eq("mzML")
  end

  it "should correctly extract the database from an input file" do
    dbname=PepXML.new(@omssa_pepxml).extract_db()
    expect(dbname).to eq("/Users/icooke/Desktop/iptest/AASequences.fasta")
  end
  
  it "should correctly extract the search engine name from an input file" do
    engine=PepXML.new(@omssa_pepxml).extract_engine()
    expect(engine).to eq("omssa")    
  end

  it "should correctly extract the enzyme from an input file" do
    enzyme=PepXML.new(@omssa_pepxml).extract_enzyme()
    expect(enzyme).to eq("trypsin")
  end

end
