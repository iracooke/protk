require 'protk/tool'

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

RSpec.shared_examples "a protk tool with default file output" do

	before(:each) do
		@tool_name=subject[0]
		@output_ext=subject[1]
		@suffix=subject[2]
		@prefix=""
		throw "@input_file must be defined to use this example" unless @input_file
		throw "@extra_args must be defined to use this example" unless @extra_args
		@default_output_file=Tool.default_output_path(@input_file,@output_ext,@prefix,@suffix)
	end

	it "produces a default output file" do
		%x[#{@tool_name} #{@extra_args} #{@input_file}]
		expect(@default_output_file).to exist?
	end
end

RSpec.shared_examples "a protk tool that defaults to stdout" do

	before(:each) do
		@tool_name=subject[0]
	end

	it "should produce a default output file" do
		output=%x[#{@tool_name} #{input_file}]

		match_text=match_requirement[0]
		expected_num_matches=match_requirement[1]
		n_matches=0
		output.each_line { |line| n_matches+=1 if line=~/#{match_text}/ }
		expect(n_matches).to eq(expected_num_matches)
	end

end

RSpec.shared_examples "a protk tool with default file output from multiple inputs" do

	before(:each) do
		@tool_name=subject[0]
		@output_ext=subject[1]
		@suffix=subject[2]
		@prefix=""
		throw "@input_files must be defined to use this example" unless @input_files
		throw "@extra_args must be defined to use this example" unless @extra_args
		@default_output_file=Tool.default_output_path(@input_files[0],@output_ext,@prefix,@suffix)
	end

	it "should produce a default output file" do
		%x[#{@tool_name} #{@extra_args} #{@input_files.join(" ")}]
		expect(@default_output_file).to exist?
	end

end

