require 'protk/galaxy_stager'
require 'tempfile'

describe GalaxyStager do
  
  let(:file) { Tempfile.new(['dataset_4', '.dat']).path }
  let(:input_name) { File.basename(file) }
  let(:tempdir) { Dir.mktmpdir }

  before do
    allow(Dir).to receive(:pwd).and_return( tempdir )
  end

  after do
	FileUtils.remove_entry_secure tempdir	
  end

  it "staged file should use original basename if none specified" do
  	expect(File.basename(GalaxyStager.new(file).staged_path)).to eq(input_name)
  end

  it "should allow specifing name of staged file" do
	   expect(File.basename(GalaxyStager.new(file, :name =>'test.pep.xml').staged_path)).to eq('test.pep.xml')  	
  end

  it "should allow specifing new extension for staged file" do 
	   expect(File.basename(GalaxyStager.new(file, :extension =>'.pep.xml').staged_path)).to eq("#{input_name}.pep.xml")
  end

end
