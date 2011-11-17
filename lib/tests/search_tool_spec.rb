# Unit tests for the SearchTool class
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../")

require 'search_tool'


describe SearchTool do

  it "should yield itself when intialised in a block" do
    st=SearchTool.new do |st|
      st.class.should==SearchTool
    end    
  end 
  
  it "should permit additional options to be defined" do
    
    st=SearchTool.new({:database=>true})
    st.option_parser.class.should==OptionParser
    st.database.class.should==String

    st.options.test=false
    st.option_parser.on( '-t', '--test', 'a test option' ) do 
      st.options.test = true
    end
    
    st.options.test.class.should==FalseClass
    
  end
  
  it "allows access to options via method_missing" do
    
    st=SearchTool.new({:database=>true})
    
    st.database.class.should==String
    
  end
    
end