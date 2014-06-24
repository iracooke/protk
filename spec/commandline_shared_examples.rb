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
		prefix="" unless defined? prefix
		@default_output_file=Tool.default_output_path(input_file,output_ext,prefix,suffix)
	end

	it "produces a default output file" do
		%x[#{@tool_name} #{extra_args} #{input_file}]
		expect(@default_output_file).to exist?
		expect(@default_output_file).to validator1 if defined? validator1
	end

	it "produces a default output file when run using relative paths" do
		Dir.chdir(@tmp_dir) do
			rinput_file=Pathname.new(input_file).basename.to_s
			expect(@default_output_file).not_to exist?
			%x[#{@tool_name} #{extra_args} #{rinput_file}]
			expect(@default_output_file).to exist?
			expect(@default_output_file).to validator if defined? validator
			expect(@default_output_file).to validator1 if defined? validator1
		end
	end


end


RSpec.shared_examples "a protk tool that supports explicit output" do

	before(:each) do
		@tool_name=subject[0]
	end

	it "produces a valid output file with the specified name" do
		%x[#{@tool_name} #{input_file} #{extra_args} -o #{output_file}]
		expect(output_file).to validator
	end

end

RSpec.shared_examples "a protk tool that defaults to stdout" do

	before(:each) do
		@tool_name=subject[0]
	end

	it "produces valid output" do
		output=%x[#{@tool_name} #{extra_args} #{input_file}]
		expect(output).to validator if defined? validator
	end

end




RSpec.shared_examples "a protk tool with default file output from multiple inputs" do

	before(:each) do
		@tool_name=subject[0]
		prefix="" unless defined? prefix
		@default_output_file=Tool.default_output_path(input_files[0],output_ext,prefix,suffix)
	end

	it "should produce a default output file" do
		%x[#{@tool_name} #{extra_args} #{input_files.join(" ")}]
		expect(@default_output_file).to exist?
		expect(@default_output_file).to validator if defined? validator
	end

end

