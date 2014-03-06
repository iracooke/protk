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

tool.options.gene2go=nil
tool.option_parser.on('--gene2go pathtogene2go','Path to gene2go database. If provided GO terms will be looked up') do |gene2go|
	tool.options.gene2go=gene2go
end

tool.options.gitogeneid=nil
tool.option_parser.on('--gitogeneid gitogeneid.db','Path to GDBM formatted gi to geneid mapping database. If provided gene ids will be looked up') do |gitogeneid|
	tool.options.gitogeneid=gitogeneid
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

$gitogeneid = nil
if (tool.gitogeneid!=nil) && (File.exist? tool.gitogeneid)
	require 'gdbm'
	$gitogeneid = GDBM.new(tool.gitogeneid,flags=GDBM::READER)
end


$gene2go = nil
if (tool.gene2go!=nil) && (File.exist? tool.gene2go)
	require 'gdbm'
	$gene2go = GDBM.new(tool.gene2go,flags=GDBM::READER)
end

def gi_from_hit_id(hit_id)
	gi_scan=hit_id.scan(/gi\|(\d+)/)
	gi_scan.join("")
end

def generate_line(hsp,hit,query,hit_seq=nil)

	line="#{query.query_id}\t#{query.query_def}\t#{hit.hit_id}\t#{hit.hit_num}\t#{hit.hit_def}\t#{hit.accession}\t#{hsp.hsp_num}\t#{hsp.bit_score}\t#{hsp.evalue}\t#{hsp.qseq}\t#{hsp.hseq}"
	if hit_seq
		line << "\t#{hit_seq}"
	end
	geneid=""
	goterm=""
	if $gitogeneid
		geneid=$gitogeneid[gi_from_hit_id(hit.hit_id)]
		goterm=$gene2go[geneid] if geneid!=nil	&& $gene2go
	end


	# throw "No geneid" if geneid==nil
	line << "\t#{geneid}\t#{goterm}"
#	require 'debugger';debugger
#	puts gi_from_hit_id(hit.hit_id)
#	puts $gene2go[gi_from_hit_id(hit.hit_id)]
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
			out_line=generate_line(hsp,hit,query,hit_seq)

			out_file.write out_line
		end
#	end
	end
end


$gitogeneid.close if $gitogeneid!=nil
$gene2go.close if $gene2go!=nil

#require 'debugger';debugger

#puts "Hi"