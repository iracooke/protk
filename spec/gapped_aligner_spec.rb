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
		alignment.trace.should eql [1, 1, 1, 0, 0, 0, 0, 0, 0, 1, 1, 1]
		alignment.gaps.should eql []
	end


	it "should align over a gap" do
		reference="ggtttttgcaggagg"
		# Translation is GFCRR
		subject="FR"
		alignment = @aligner.align(subject,reference)
		alignment.class.should eql PeptideToGeneAlignment
		alignment.trace.should eql [1, 1, 1, 0, 0, 0, 1,1,1, 1, 1, 1, 0, 0, 0]
		alignment.gaps.should eql [[6,12]]
	end

	it "should align over a gap including a frameshift" do
		reference="ggtttttcaggagg"
		# Translation is GF*RR
		subject="FR"
		alignment = @aligner.align(subject,reference)
		alignment.class.should eql PeptideToGeneAlignment
		alignment.trace.should eql [1, 1, 1, 0, 0, 0, 1,1,1, 1, 1,  0, 0, 0]
		alignment.gaps.should eql [[6,11]]
	end

end