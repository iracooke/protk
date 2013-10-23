#!/usr/bin/env ruby
#
# This file is part of protk
#
# 

require 'protk/constants'
require 'protk/tool'
require 'bio'
require 'protk/fastadb'
require 'bio-blastxmlparser'


tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Dump BLAST xml to tabular format.\n\nUsage: blastxml_to_table.rb blast.xml"

tool.options.database=nil
tool.option_parser.on( '-d filename','--database filename', 'Database used for BLAST search. If provided, hit sequences will be looked up in this database' ) do |file| 
  tool.options.database=file
end

exit unless tool.check_options 

#require 'debugger';debugger

exit unless ARGV.length == 1
input_file=ARGV[0]

out_file=$stdout
if ( tool.explicit_output != nil)
  out_file=File.open(tool.explicit_output, "w")
end

$fastadb = nil
if tool.database
	$fastadb=FastaDB.new(tool.database)
end

def generate_line(hsp,hit,query,hit_seq=nil)
	line="#{query.query_id}\t#{hit.hit_id}\t#{hit.hit_num}\t#{hit.hit_def}\t#{hsp.hsp_num}\t#{hsp.bit_score}\t#{hsp.evalue}\t#{hsp.qseq}\t#{hsp.hseq}"
	if hit_seq
		line << "\t#{hit_seq}"
	end
	line<<"\n"
	line
end

def fetch_hit_seq(hit)
	hit_seq=nil
	if $fastadb
		hit_seq=$fastadb.fetch(hit.hit_id).first.aaseq
	end
	hit_seq
end

blast = Bio::BlastXMLParser::XmlSplitterIterator.new(input_file).to_enum

blast.each do |query|  
	query.hits.each do |hit|
#	hit=query.hits.first
#	if hit
		hit_seq=fetch_hit_seq(hit)
		hit.hsps.each do |hsp|
			out_file.write generate_line(hsp,hit,query,hit_seq)
		end
#	end
	end
end

#require 'debugger';debugger

#puts "Hi"