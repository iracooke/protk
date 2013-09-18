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

	it "should align over a gap" do
		reference="ABCDEFGHI"
		subject="ABFG"
		alignment = @aligner.align(subject,reference)
		alignment[0].class.should eql PeptideFragment
	end


end