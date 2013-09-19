require 'rspec'
require 'protk/gapped_aligner'
require 'spec_helper'
require 'bio'
require 'tempfile'


describe GappedAligner do 

	before :each do
		@aligner=GappedAligner.new()
	end

	it "should respond to the align command" do

		@aligner.respond_to?(:align).should be_true
	end

	it "should align with no gaps" do
		reference="ggtttttgcagg"
		# Translation is GFCR
		subject="FC"
		alignment = @aligner.align(subject,reference)
		alignment.class.should eql PeptideToGeneAlignment
		alignment.trace.should eql [1, 1, 1, 0, 0, 0, 0, 0, 0]
		alignment.gaps.should eql []
	end


	it "should align over a gap preferring a shorter gap" do
		reference="ggtttttgcaggaggtgc"
		# Translation is GFCRRC
		subject="FR"
		alignment = @aligner.align(subject,reference)
		alignment.class.should eql PeptideToGeneAlignment
		# require 'debugger';debugger
		alignment.trace.should eql [1, 1, 1, 1, 0, 0, 0, 1, 1, 0, 0, 0]
		alignment.gaps.should eql [[7,9]]
	end

	# it "should align over a gap including a frameshift" do
	# 	reference="ggtttttcaggagg"
	# 	# Translation is GF*RR
	# 	subject="FR"
	# 	alignment = @aligner.align(subject,reference)
	# 	alignment.class.should eql PeptideToGeneAlignment
	# 	require 'debugger';debugger
	# 	alignment.trace.should eql [1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]
	# 	alignment.gaps.should eql []
	# end

	# it "should deal with frameshifts at the start" do
	# 	reference="tggtttttgcaggaggtgc"
	# 	# Translation is GFCRRC in frame 2
	# 	subject="RC"
	# 	alignment = @aligner.align(subject,reference)
	# 	require 'debugger';debugger

	# 	alignment.class.should eql PeptideToGeneAlignment
	# 	alignment.trace.should eql [1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 0, 0, 0, 0, 0, 0]
	# 	alignment.gaps.should eql []
	# end

	it "can align a real case" do
		reference="catgggtggtatcccaactaagtacactggtgaagtcctcacagtcgatgagaacggaaaggacaaggtcgttccaggtctattcgcctgcggtgaggctgcctgtgtgtccgttcacggtgccaatcgtctcggagctaactctctgctcgatcttatcgtcttcggtcgtgctgtctcccacactattcgtgataacttttcgcctggctacaagcaccccgagatttcggctgatgccggagccgaatctatttctgtcatcgatcagatgcgaaccgccgacggatccaagtccacagctgacattcgtcttgaaatgcagaaggtcatgcagactgatgtctctgtcttccgtactcaagaatcactggatgaaggtgtaaagaagattcaccaggtggaccagagctttgccgatgtcggaactaaagacagaagcatgatctggaactctgatctagttgagaccttggagttgaggaatttgttaacttgcgcgtatgtcatcaacttctcactagtttatgatgatcacagctaatatgttaccagtgttcaaaccgctgaggcagcagctaaccgaaaggaatcgcgtggtgcccacgcacgagaggattatccagaccgtgatgacgagaaatggatgaagcacacactgacgtggcagaagtcgcctcatagcaaggttgacattggttaccgtgccgtcacatctcacactcttgatgaggccgagtgcaaggctgttcctcctttcaagcgtacttattag"
		subject = "NLLTCAVQTAEAAANR"		
		alignment = @aligner.align(subject,reference)
		alignment.class.should eql PeptideToGeneAlignment
		require 'debugger';debugger
		alignment.gaps.length.should eql 1
	end

end