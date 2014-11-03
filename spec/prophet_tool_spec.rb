require 'protk/prophet_tool'
require 'spec_helper'

describe ProphetTool do

  
  it "translates enzyme names to xinteract enzyme codes" do

    expect(ProphetTool.xinteract_code_for_enzyme('trypsin')).to eq("T")
    expect(ProphetTool.xinteract_code_for_enzyme('chymotrypsin')).to eq("C")

  end
    
end