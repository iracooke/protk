require 'protk/command_runner'


describe CommandRunner do

  it "should run a basic system command and obtain a valid status value" do
    genv=Constants.new
    cr=CommandRunner.new(genv)
    expect(cr.run_local("ls")).to eq(0)
  end
  
end