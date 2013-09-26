#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 4/9/2013
#
# 

require 'protk/constants'
require 'protk/tool'
require 'bio'

tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Create a protein database from Augustus gene prediction output that is suitable for later processing by proteogenomics tools.\n\nUsage: augustus_to_proteindb.rb [options] augustus.gff3"

tool.options.add_transcript_info=false
tool.option_parser.on( '--info', 'Include CDS coordinates' ) do  
  tool.options.add_transcript_info=true
end

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

inname=ARGV.shift

$add_transcript_info=tool.add_transcript_info

$print_progress=true

outfile=nil
if ( tool.explicit_output != nil)
  outfile=File.open(tool.explicit_output,'w')
else
  outfile=$stdout
  $print_progress=false
end


def get_transcript_lines(gene_lines)
  transcripts=[]
  gene_lines.each do |line|  
    if line =~ /transcript\t(\d*?)\t/
      transcripts << line
    end
  end
  transcripts
end

def get_cds_lines(gene_lines)
  coding_sequences=[]
  gene_lines.each do |line|  
    if line =~ /CDS\t(\d*?)\t/
      coding_sequences << line
    end
  end
  coding_sequences
end

$capturing_protein=false

def capture_protein_start(line)
    if line=~/protein sequence = \[/
      $capturing_protein=true     
    end
end

def at_protein_end(line)
  if $capturing_protein && line =~ /# .*?\]/
    return true    
  end
  return false
end

def get_protein_sequence_lines(gene_lines)
  $capturing_protein=false
  proteins=[]
  current_protein_lines=[]
  gene_lines.each do |line|  
    capture_protein_start(line)
    if at_protein_end(line)
      current_protein_lines << line
      proteins << current_protein_lines 
      current_protein_lines=[]
      $capturing_protein=false   
    else
      current_protein_lines << line if $capturing_protein
    end
  end
  proteins
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

def sequence_fasta_header(transcript_line,coding_sequences,scaffold)

  tmatch=transcript_line.match(/transcript\t(\d+)\t(\d+).*?([-\+]{1}).*?ID=(.*?);/)
#  require 'debugger'; debugger
  tstart=tmatch[1]
  tend=tmatch[2]
  tstrand="fwd"
  tstrand = "rev" if tmatch[3]=="-"

  tid=tmatch[4]
  header=">lcl|#{scaffold}_#{tstrand}_#{tid} #{tstart}|#{tend}"
  if $add_transcript_info
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

def parse_gene(gene_lines)

  geneid=gene_lines[0].match(/start gene (.*)/)[1]
  transcripts=get_transcript_lines(gene_lines)
  coding_sequences=get_cds_lines(gene_lines)
  proteins=get_protein_sequence_lines(gene_lines)
  fasta_string=""
  throw "transcripts/protein mismatch" unless transcripts.length == proteins.length
  transcripts.each_with_index do |ts, i|  
    fh=sequence_fasta_header(ts,coding_sequences,$current_scaffold)
    fasta_string << "#{fh}\n"
    ps=protein_sequence(proteins[i])  
    fasta_string << "#{ps}\n"
  end

  gene_lines=[]
  $capturing_gene=false
  fasta_string
end

def capture_scaffold(line)
  if line =~ /-- prediction on sequence number.*?name = (.*)\)/
    $current_scaffold=line.match(/-- prediction on sequence number.*?name = (.*)\)/)[1]
    if ( $print_progress)
      puts $current_scaffold
    end
  end
end

def capture_gene_start(line)
  if line =~ /# start gene/
    $capturing_gene=true
  end
end

def at_gene_end(line)
  if line =~ /# end gene/
    return true
  end
  return false
end

$current_scaffold=""
gene_lines=[]
$capturing_gene=false


File.open(inname).each_with_index do |line, line_i|  
  line.chomp!
  capture_scaffold(line)
  capture_gene_start(line)

  if at_gene_end(line)
    gene_string=parse_gene(gene_lines)
    outfile.write gene_string
    gene_lines=[]
  else
    gene_lines << line if $capturing_gene
  end

end