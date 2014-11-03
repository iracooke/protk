
def generate_params_doc(test_attributes)
	params_doc = XML::Document.new()
	params_doc.root = XML::Node.new('bioml')
	test_attributes.each_pair do |tandem_key, val|  
		node = XML::Node.new('note')
    	node["type"] = "input"
    	node["label"] = tandem_key
    	node.content = val.to_s
    	params_doc.root << node
	end
	params_doc
end

# Assumes that ARGV has been set prior to calling this
#
def params_doc_by_parsing_argv()
	xtd=TandemSearchTool.new
	xtd.check_options
	xtd.params_doc(@db_info_with_full_path,"taxonomy.xml","input.mgf","output.tandem")
end


RSpec.shared_examples "an xtandem option" do |commandlineval,generatedval,externalval|

	before(:each) do
    	@tandem_key=subject[0]
    	@flag=subject[1]
	end

    it "is parsed from argv" do
    	ARGV+=[@flag,commandlineval.to_s]
    	pdoc=params_doc_by_parsing_argv
    	expect(pdoc).to have_tandem_param(@tandem_key)
		expect(value_for_tandem_param(pdoc,@tandem_key)).to eq(generatedval.to_s)
    end

    it "can be set in an external parameter file" do
		params_path = "#{@tmp_dir}/test.params"

		input_params_doc = generate_params_doc({@tandem_key=>externalval.to_s})
		input_params_doc.save(params_path)

		expect(input_params_doc).to have_tandem_param(@tandem_key)
		expect(value_for_tandem_param(input_params_doc,@tandem_key)).to eq(externalval.to_s)

		ARGV+=["--tandem-params",params_path]
		params_doc = params_doc_by_parsing_argv

		expect(params_doc).to have_tandem_param("list path, default parameters")
		expect(value_for_tandem_param(params_doc,"list path, default parameters")).to eq(params_path)

		expect(params_doc).not_to have_tandem_param(@tandem_key)
    end

    it "overrides value in external parameter file if set on the commandline" do
		params_path = "#{@tmp_dir}/test.params"


		input_params_doc = generate_params_doc({@tandem_key=>externalval.to_s})
		input_params_doc.save(params_path)

		expect(input_params_doc).to have_tandem_param(@tandem_key)
		expect(value_for_tandem_param(input_params_doc,@tandem_key)).to eq(externalval.to_s)

		ARGV+=["--tandem-params",params_path,@flag,commandlineval.to_s]
		params_doc = params_doc_by_parsing_argv

		expect(params_doc).to have_tandem_param("list path, default parameters")
		expect(value_for_tandem_param(params_doc,"list path, default parameters")).to eq(params_path)

		expect(params_doc).to have_tandem_param(@tandem_key)
		expect(value_for_tandem_param(params_doc,@tandem_key)).to eq(generatedval.to_s)
    end

end


RSpec.shared_examples "a parsed motif option" do |commandlineval,generatedval|

	before(:each) do
    	@tandem_key=subject[0]
    	@flag=subject[1]
	end

    it "is parsed from argv" do
    	ARGV+=[@flag,commandlineval.to_s]
    	pdoc=params_doc_by_parsing_argv
    	expect(pdoc).to have_tandem_param(@tandem_key)
		expect(value_for_tandem_param(pdoc,@tandem_key)).to eq(generatedval.to_s)
    end

end
