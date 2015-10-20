require 'protk/tool'

RSpec.shared_examples "a protk tool" do 

	before(:each) do
		@tool_name=subject[0]
	end

	it "is installed" do
		output=%x[which #{@tool_name}]
		expect(output).to match(/#{@tool_name}$/)
	end

	it "prints help text if no arguments are given" do
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
		expect(@default_output_file).to validator1 if defined? validator1		
	end

	it "produces a default output file when run using relative paths" do
		Dir.chdir(tmp_dir) do
			rinput_file=Pathname.new(input_file).basename.to_s
			expect(@default_output_file).not_to exist?
			%x[#{@tool_name} #{extra_args} #{rinput_file}]
			expect(@default_output_file).to exist?
			expect(@default_output_file).to validator if defined? validator
			expect(@default_output_file).to validator1 if defined? validator1
		end
	end


end

RSpec.shared_examples "a protk tool that works with galaxy" do

	before(:each) do
		@tool_name=subject[0]
	end

	it "produces a valid output file in its galaxy working dir" do
		Dir.chdir(working_dir) do
			%x[#{@tool_name} #{extra_args} #{input_file} -o #{output_file}]
			expect(output_file).to exist?
			expect(output_file).to validator if defined? validator
			expect(output_file).to validator1 if defined? validator1
			expect(output_file).to validator2 if defined? validator2
		end
	end


end


RSpec.shared_examples "a protk tool that supports explicit output" do

	before(:each) do
		@tool_name=subject[0]
	end

	it "produces a valid output file with the specified name" do
		%x[#{@tool_name} #{input_file} #{extra_args} -o #{output_file}]
		expect(output_file).to validator if defined? validator
		expect(output_file).to validator1 if defined? validator1
	end

end

RSpec.shared_examples "a protk tool that defaults to stdout" do

	before(:each) do
		@tool_name=subject[0]
	end

	it "produces valid output" do
		output=%x[#{@tool_name} #{extra_args} #{input_file}]
		expect(output).to validator if defined? validator
		expect(output).to validator1 if defined? validator1
		expect(output).to validator2 if defined? validator2
		expect(output).to validator3 if defined? validator3
		expect(output).to validator4 if defined? validator4
		expect(output).to validator5 if defined? validator5
		expect(output).to validator6 if defined? validator6
	end

end


RSpec.shared_examples "a protk tool that merges multiple inputs" do

	before(:each) do
		@tool_name=subject[0]
		prefix="" unless defined? prefix
		@default_output_file=Tool.default_output_path(input_files,output_ext,prefix,suffix)
	end

	it "produces a default output file" do
		%x[#{@tool_name} #{extra_args} #{input_files.join(" ")}]
		expect(@default_output_file).to exist?
		expect(@default_output_file).to validator if defined? validator
	end

end

RSpec.shared_examples "a protk tool that handles multiple inputs sequentially" do

	before(:each) do
		@tool_name=subject[0]
		prefix="" unless defined? prefix
		@default_output_files=input_files.each { |input_file| Tool.default_output_path(input_file,output_ext,prefix,suffix) }
	end

	it "produces several default output files" do
		%x[#{@tool_name} #{extra_args} #{input_files.join(" ")}]
		@default_output_files.each do |output_file|  
			expect(output_file).to exist?
			expect(output_file).to validator if defined? validator
		end
	end

end
