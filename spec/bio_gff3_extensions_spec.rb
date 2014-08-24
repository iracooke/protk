require 'spec_helper'
require 'protk/bio_gff3_extensions'
require 'rspec/its'


describe Bio::GFF::GFF3::Record do 

	include_context :tmp_dir_with_fixtures, ["transdecoder_gff.gff3","augustus_sample.gff"]

	let(:transdecoder_gff) { 
		gffdb = Bio::GFF::GFF3.new(File.read("#{@tmp_dir}/transdecoder_gff.gff3"))
		gffdb
	}

	let(:augustus_gff) { 
		gffdb = Bio::GFF::GFF3.new(File.read("#{@tmp_dir}/augustus_sample.gff"))
		gffdb
	}

	describe "a record" do
		it "should return its length" do
			rec = transdecoder_gff.records[0]
			expect(rec.length).to eq(323)
		end

	end

	describe "an array of records" do

		it "should be sortable by start position" do
			records = transdecoder_gff.records[(1...4)]
			expect(records[2].start).to eq(1)
			expect(records.sort[2].start).to eq(203)
		end

	end



end