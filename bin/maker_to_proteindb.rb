#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 4/9/2013
#
# 

require 'protk/constants'
require 'protk/tool'
require 'protk/gff_to_proteindb_tool'
require 'bio'

tool=GffToProteinDBTool.new([:explicit_output,:debug,:add_transcript_info])
tool.option_parser.banner = "Create a protein database from Maker gene prediction \
output that is suitable for later processing by proteogenomics tools.\
\n\nUsage: maker_to_proteindb.rb [options] maker.gff3"

tool.add_value_option(:proteins_file,nil,['-p', '--prot-fasta proteins', 'A fasta file \
	containing protein sequences for each transcript'])

# tool.add_value_option(:explicit_output,nil,['-o', '--output out', 'An explicitly named output file. \
#   The default is to write to standard output'])

exit unless tool.check_options(true)

inname=ARGV.shift

$protk = Constants.instance
log_level = tool.debug ? :debug : :fatal
$protk.info_level= log_level

tool.print_progress=true

outfile=nil
if ( tool.explicit_output != nil)
  outfile=File.open(tool.explicit_output,'w')
else
  outfile=$stdout
  tool.print_progress=false
end

gene_lines=[]

def get_protein_sequence(transcript_id,proteins_file)
	%x[samtools faidx #{proteins_file} #{transcript_id} | tail -n +2]
end

def cds_to_header_text(coding_sequence,transcript_id)
#  require 'debugger';debugger
  imatch=coding_sequence.match(/CDS\t(\d+)\t(\d+).*?([-\+]{1}.*?Parent=#{transcript_id})$/)
  if imatch==nil
    return ""
  end
  istart=imatch[1]
  iend=imatch[2]
  "#{istart}|#{iend}"
end

def sequence_fasta_header(tool,transcript_line,coding_sequences)

  tmatch=transcript_line.match(/mRNA\t(\d+)\t(\d+).*?([-\+]{1}).*?ID=(.*?);/)
#  require 'debugger'; debugger
  tstart,tend,tstrand = transcript_line.match(/mRNA\t(\d+)\t(\d+).*?([-\+]{1})/).captures

  # tstart=tmatch[1]
  # tend=tmatch[2]
#  tsidfield = transcript_line.split("\t")[8]

  tid = transcript_line.match(/ID=([^;]+)/).captures[0]
  # if tsidfield =~ /ID=/
  #   tid = tsidfield.match(/ID=(.*?);/).captures[0]
  # else
  #   tid = tsidfield.gsub(" ","_").gsub(";","_")
  # end

   # require 'byebug';byebug

  tstrandfr="fwd"
  tstrandfr = "rev" if tstrand=="-"

  scaffold=transcript_line.split("\t")[0]

  # tid=tmatch[4]
  header=">lcl|#{scaffold}_#{tstrandfr}_#{tid} #{tstart}|#{tend}"
  if tool.add_transcript_info
    coding_sequences.each { |coding_sequence| header << " #{cds_to_header_text(coding_sequence,tid)}" }
  end
  header
end

def protein_sequence(protein_lines)
  seq=""
  protein_lines.each_with_index do |line, i|  
      seq << line.match(/(\w+)\]?$/)[1]
 end

  seq
end


def parse_gene(tool,gene_lines)

	# require 'byebug';byebug
	geneid=gene_lines[0].match(/ID=([^;]+)/).captures[0]

	scaffold_id = gene_lines[1].split("\t")[0]

	transcripts=tool.get_lines_matching(/mRNA/,gene_lines)

	coding_sequences=tool.get_lines_matching(/CDS/,gene_lines)

	fasta_string=""
	
	transcripts.each_with_index do |ts, i|

  		prot_id=ts.match(/ID=([^;]+)/).captures[0]

		begin
	  		fh=sequence_fasta_header(tool,ts,coding_sequences)
  			fasta_string << "#{fh}\n"
  			ps=get_protein_sequence(prot_id,tool.proteins_file)  
  			fasta_string << "#{ps}"
  		rescue => e
  			$protk.log "Unable to retrieve protein for #{prot_id} #{e}" , :debug
  		end
	end

	fasta_string
end



File.open(inname).each_with_index do |line, line_i|  
  line.chomp!

  if tool.start_new_gene(line)
  	if gene_lines.length > 0
	    gene_string=parse_gene(tool,gene_lines)
	    outfile.write gene_string
	    gene_lines=[]
	end
  end

  if line =~ /maker/
    gene_lines << line
  end

end