# Unit tests for the MascotUtil class
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/../")

require 'mascot_util'


describe MascotUtil do
  
  it "should successfully read the basename of its original input file" do

    MascotUtil.input_basename("data/mascot_results.dat").should=="dataset_600"

  end
    
end