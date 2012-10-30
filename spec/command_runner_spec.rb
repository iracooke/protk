require 'protk/command_runner'


describe CommandRunner do

  it "should run a basic system command and obtain a valid status value" do

    genv=Constants.new
    
    cr=CommandRunner.new(genv)
    cr.run_local("ls").should==0

  end
  
end