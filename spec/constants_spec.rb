# Unit tests for the Constants class
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../")

require 'constants'


describe Constants do

  before do
    @constants=Constants.new
  end
  

  it "should allow access to configuration constants through same named methods" do      
    @constants.openms_bin.class.should==String    
  end
  
  it "should allow access to boolean constants" do
    @constants.has_pbs.class.should==(FalseClass || TrueClass)
  end
  
end
