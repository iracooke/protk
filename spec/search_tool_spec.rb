require 'protk/search_tool'


describe SearchTool do

  it "should yield itself when intialised in a block" do
    st=SearchTool.new do |st|
      expect(st.class).to eq(SearchTool)
    end    
  end 
  
  it "should permit additional options to be defined" do
    
    st=SearchTool.new({:database=>true})
    expect(st.option_parser.class).to eq(OptionParser)
    expect(st.database.class).to eq(String)

    st.options.test=false
    st.option_parser.on( '-t', '--test', 'a test option' ) do 
      st.options.test = true
    end
    
    expect(st.options.test.class).to eq(FalseClass)
    
  end
  
  it "allows access to options via method_missing" do
    
    st=SearchTool.new({:database=>true})
    
    expect(st.database.class).to eq(String)
    
  end
    
end