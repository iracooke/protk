require 'protk/constants'


describe Constants do

  before do
    @constants=Constants.new
  end
  


  describe "default paths" do
  	before :each do
  		@pk_dir = @constants.protk_dir
  	end
  	subject {@constants}
  	it { should respond_to :protk_dir }

  	its(:openms_root) {should == "#{@pk_dir}/tools/openms"}
  	its(:blast_root) {should == "#{@pk_dir}/tools/blast"}
    its(:omssa_root) {should=="#{@pk_dir}/tools/omssa"}
    its(:omssacl) {should=="#{@pk_dir}/tools/omssa/omssacl"}
    its(:omssa2pepxml) {should == "#{@pk_dir}/tools/omssa/omssa2pepXML"}
    its(:makeblastdb) {should=="#{@pk_dir}/tools/blast/bin/makeblastdb"}
  	its(:tpp_root) {should == "#{@pk_dir}/tools/tpp"}
    its(:xinteract) {should=="#{@pk_dir}/tools/tpp/bin/xinteract"}
    its(:xtandem) {should match "#{@pk_dir}/tools/tpp/bin/tandem"}
    its(:tandem2xml) {should == "#{@pk_dir}/tools/tpp/bin/Tandem2XML"}
    its(:interprophetparser) { should == "#{@pk_dir}/tools/tpp/bin/InterProphetParser"}
    its(:proteinprophet) { should == "#{@pk_dir}/tools/tpp/bin/ProteinProphet"}
    its(:mascot2xml) { should == "#{@pk_dir}/tools/tpp/bin/Mascot2XML"}
  	its(:protein_database_root) {should == "#{@pk_dir}/Databases"}
  	its(:log_file) {should=="#{@pk_dir}/Logs/protk.log"}
  end
  
  it "should allow access to boolean constants" do
    @constants.tpp_root.class.should==String
  end
  
end
