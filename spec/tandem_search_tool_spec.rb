require 'spec_helper.rb'
require 'tandem_shared_examples.rb'
require 'protk/tandem_search_tool'


RSpec.shared_context :taxonomy_file do 
  before(:each) do
  	@testdb_full_path=Pathname.new("#{$this_dir}/data/testdb.fasta").realpath.to_s
  	@testdb_relative_path="data/testdb.fasta"
  	@faketaxon="faketaxon"

  	@db_info_with_full_path=FastaDatabase.new(@faketaxon,@testdb_full_path)  	
  end
  let(:shared_params_doc) {
  	xtd=TandemSearchTool.new
  	xtd.params_doc(@db_info_with_full_path,"taxonomy.xml","input.mgf","output.tandem")
  }
end

RSpec.shared_context :test_argv do
	before(:each) do
		@saved_argv=ARGV
		ARGV=[]
	end

	after(:each) do
		ARGV=@saved_argv
	end
end

RSpec.shared_context :tmpdir do 

  before(:each) do
    @tmp_dir=Dir.mktmpdir
  end

  after(:each) do
  	FileUtils.remove_entry @tmp_dir
  end

end

RSpec::Matchers.define :have_one_node  do |node_path,attributes|
  match do |xmldoc|
  	matching_nodes=xmldoc.find(node_path)
  	return(false) if matching_nodes.length!=1
  	node=matching_nodes[0]
  	attributes.each_pair do |key, val|
  		unless node[key]==val
  			puts "#{node[key]} does not match #{val}"
		  	return(false) 
  		end
  	end
  end
end

RSpec::Matchers.define :have_tandem_param  do |tandem_key|

  match do |xmldoc|
  	notes = xmldoc.find("/bioml/note[@type=\"input\" and @label=\"#{tandem_key}\"]")
  	@num_notes=notes.length
  	notes.length==1
  end
  failure_message do |xmldoc|
    "\nexpected that xmldoc would have a single instance of #{tandem_key}\nbut found #{@num_notes} instances\n"
  end
  failure_message_when_negated do |xmldoc|
    "\nexpected that xmldoc would not have a single instance of #{tandem_key}\nbut #{@num_notes} instances were found\n"
  end
end

# You should check that the key exists before using this
def value_for_tandem_param(xmldoc,tandem_key)
	notes = xmldoc.find("/bioml/note[@type=\"input\" and @label=\"#{tandem_key}\"]")
	throw "No such key #{tandem_key} in xml document" unless notes.length>0
	throw "Ambiguous key #{tandem_key} in xml document" unless notes.length==1
	notes[0].content
end


describe TandemSearchTool do 

	include_context :taxonomy_file
	include_context :test_argv

	it "should generate a taxonomy doc using full path to fasta file" do
		xtd=TandemSearchTool.new
		taxo_doc=xtd.taxonomy_doc(@db_info_with_full_path)
		expect(taxo_doc).to have_one_node("/bioml/taxon/file",{:format=>"peptide",:URL=>@testdb_full_path})
	end

	describe "basic parameter file" do

		it "should should be a bioml document" do
			expect(shared_params_doc.root.name).to eq("bioml")
		end

		it "should define an input file" do
			expect(shared_params_doc).to have_tandem_param("spectrum, path")
			expect(value_for_tandem_param(shared_params_doc,"spectrum, path")).to eq("input.mgf")
		end

		it "should define a taxonomy file" do
			expect(shared_params_doc).to have_tandem_param("list path, taxonomy information")
			expect(shared_params_doc).to have_tandem_param("protein, taxon")
			expect(value_for_tandem_param(shared_params_doc,"list path, taxonomy information")).to eq("taxonomy.xml")
			expect(value_for_tandem_param(shared_params_doc,"protein, taxon")).to eq(@faketaxon)
		end

		it "should define an output path" do
			expect(shared_params_doc).to have_tandem_param("output, path")
			expect(value_for_tandem_param(shared_params_doc,"output, path")).to eq("output.tandem")
		end

	end


	describe "standard xtandem options" do
		include_context :tmpdir

		describe ["spectrum, fragment monoisotopic mass error","-f"] do
			it_behaves_like "an xtandem option", "cldummy","cldummy","filedummy"
		end

		describe ["scoring, maximum missed cleavage sites","-v"] do
			it_behaves_like "an xtandem option", "cldummy","cldummy","filedummy"
		end

		describe ["spectrum, parent monoisotopic mass error units","--precursor-ion-tol-units"] do
			it_behaves_like "an xtandem option", "ppm", "ppm", "Da"
		end

		describe ["spectrum, fragment monoisotopic mass error units","--fragment-ion-tol-units"] do
			it_behaves_like "an xtandem option", "ppm", "ppm", "Da"
		end

		describe ["spectrum, parent monoisotopic mass isotope error","--multi-isotope-search"] do
			it_behaves_like "an xtandem option", "yes","yes","no"
		end

		describe ["protein, cleavage semi","--cleavage-semi"] do
			it_behaves_like "an xtandem option", "yes","yes","no"
		end

		describe ["output, spectra", "--output-spectra"] do
			it_behaves_like "an xtandem option", "yes","yes","no"
		end

		describe ["spectrum, threads", "--threads"] do
			it_behaves_like "an xtandem option", "2","2","4"
		end

		describe ["spectrum, parent monoisotopic mass error minus","-p"] do
			it_behaves_like "an xtandem option", 5, 2.5, "250"
		end

		describe ["spectrum, parent monoisotopic mass error plus","-p"] do
			it_behaves_like "an xtandem option", 5, 2.5, "250"
		end

	end


	describe "residue modification options" do

		describe ["residue, modification mass","--fix-mods"] do
			it_behaves_like "a residue modification option", "57.021464@C , 	65.2@Q","57.021464@C,65.2@Q"
			it_behaves_like "a residue modification option", "57.021464__at__C ","57.021464@C"
		end

		describe ["residue, potential modification mass","--var-mods"] do
			it_behaves_like "a residue modification option", "15.994915@M , 	65.2@Q, 0.998@N!{P}[ST]","15.994915@M,65.2@Q"
			it_behaves_like "a residue modification option", "15.994915__at__M ","15.994915@M"
		end

		describe ["residue, potential modification motif","--var-mods"] do
			it_behaves_like "a residue modification option", "15.994915@M , 	65.2@Q, 0.998@N!{P}[ST]","0.998@N!{P}[ST]"
			it_behaves_like "a residue modification option", "0.998__at__N!__oc__P__cc____ob__ST__cb__ ","0.998@N!{P}[ST]"
		end

		describe ["residue, potential modification motif","--glyco"] do
			it_behaves_like "a residue modification option", "","0.998@N!{P}[ST]"
		end

		describe ["residue, potential modification mass","-m"] do
			it_behaves_like "a residue modification option", "","15.994915@M"
		end

	end

end




