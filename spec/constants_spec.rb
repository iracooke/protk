require 'protk/constants'


describe Constants do

  before do
    @constants=Constants.new
  end
  


  # describe "default paths" do
  # 	before :each do
  # 		@pk_dir = @constants.protk_dir
  # 	end
  # 	subject {@constants}
  # 	it { should respond_to :protk_dir }

  # 	its(:protein_database_root) {should == "#{@pk_dir}/Databases"}
  # 	its(:log_file) {should=="#{@pk_dir}/Logs/protk.log"}
  # end
  
  # it "should allow access to boolean constants" do
  #   @constants.tpp_root.class.should==String
  # end
  
end
