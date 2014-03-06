# require 'rspec'
# require 'protk/randomize'
# require 'spec_helper'
# require 'bio'
# require 'tempfile'

# def entries_in_fasta filename
# 		ff=Bio::FlatFile.new(Bio::FastaFormat,File.open(filename))
# 		ne=0
# 		ff.each_entry { |e| ne=ne+1}
# 		ne
# end

# RSpec::Matchers.define :be_decoy do
#   match do |identifier|
#           identifier =~ /^decoy_/
#       end
# end

# describe Randomize, :broken=>true do 

# 	let(:tempdir) { Dir.mktmpdir }

# 	after do
# 		FileUtils.remove_entry_secure tempdir	
# 	end

	
# 	it "should respond to the make_decoys command" do
# 		Randomize.respond_to?(:make_decoys).should be_true
# 	end

# 	it "should create a randomized version of the test database" do
# 		test_db_path = "#{$this_dir}/data/testdb.fasta"
# 		output_path = "#{tempdir}/testdb.random.fasta"
# 		Randomize.make_decoys test_db_path, 4,  output_path, "decoy_"
# 		ff=Bio::FlatFile.new(Bio::FastaFormat,File.open(output_path))
# 		ne=0
# 		ff.each_entry { |e| 
# 			ne=ne+1
# 			e.entry_id.should be_decoy
# 		}
# 		ne.should == entries_in_fasta(test_db_path)
# 	end

# end