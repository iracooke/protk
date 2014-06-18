RSpec.shared_examples "a protk tool" do 

	before(:each) do
		@tool_name=subject[0]
	end

	it "should be installed" do
		output=%x[which #{@tool_name}]
		expect(output).to match(/#{@tool_name}$/)
	end

	it "should print help text if no arguments are given" do
		output=%x[#{@tool_name}]
		expect(output).to match("Usage: #{@tool_name}")
	end
end