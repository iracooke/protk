#!/usr/bin/env ruby
#
# This file is part of protk
# Original python version created by Max Grant
# Translated to ruby by Ira Cooke 7/2/2013
#
# 

require 'protk/constants'
require 'protk/tool'
require 'bio'

tool=Tool.new(:explicit_output=>true)
tool.option_parser.banner = "Create a sixframe translation of a genome.\n\nUsage: sixframe.rb [options] genome.fasta"

tool.option_parser.parse!

inname=ARGV.shift

outfile=File.open("#{inname}.translated.fasta",'w')
if ( tool.explicit_output != nil)
  outfile=File.open(tool.explicit_output,'w')
end


file = Bio::FastaFormat.open(inname)

file.each do |entry|
  length = entry.naseq.length
  (1...7).each do |frame|
    translated_seq= entry.naseq.translate(frame)
    orfs=translated_seq.split("*")
    orf_index = 0
    position = ((frame - 1) % 3) + 1    

    oi=0
    orfs.each do |orf|
      oi+=1
      if ( orf.length > 20 )
        position_start = position
        position_end = position_start + orf.length*3 -1

        if ( frame > 3)
            position_start = length - (position - 1)
            position_end = position_start - orf.length * 3 + 1          
        end


        # Create accession compliant with NCBI naming standard
        # See http://www.ncbi.nlm.nih.gov/books/NBK7183/?rendertype=table&id=ch_demo.T5
        ncbi_scaffold_id = entry.entry_id.gsub('|','_').gsub(' ','_')
        ncbi_accession = "lcl|#{ncbi_scaffold_id}_frame_#{frame}_orf_#{oi}"

        # Output in fasta format
        outfile.write(">#{ncbi_accession} #{position_start}|#{position_end}\n#{orf}\n")

      end
      position += orf.length*3+3
    end

  end
end
