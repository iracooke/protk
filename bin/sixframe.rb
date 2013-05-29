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

def check_coords(naseq,aaseq,frame,pstart,pend)
  orf_from_coords=""
  if ( frame<=3)
    orf_from_coords=naseq[pstart-1..pend-1].translate(1)
  else
    orf_from_coords=naseq[pstart-1..pend-1].reverse_complement.translate(1)
    # current coords give
    # naseq.reverse_complement[pstart-1..pend-1].translate(1)
    # naseq[350368-pend..(350367-pstart+1)].reverse_complement.translate(1)
#    orf_from_coords=naseq[naseq.length-pend..naseq.length-pstart].reverse_complement.translate(1)
  end
  if ( orf_from_coords!=aaseq)
    require 'debugger'; debugger
  end
#  p "#{aaseq} #{frame}"
end


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

  puts entry.entry_id

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

        if ( frame>3) #On reverse strand. Coordinates need translating to forward strand
          forward_position_start=length-position_end+1
          forward_position_end = length-position_start+1
          position_start=forward_position_start
          position_end=forward_position_end
        end




        # Create accession compliant with NCBI naming standard
        # See http://www.ncbi.nlm.nih.gov/books/NBK7183/?rendertype=table&id=ch_demo.T5
        ncbi_scaffold_id = entry.entry_id.gsub('|','_').gsub(' ','_')
        ncbi_accession = "lcl|#{ncbi_scaffold_id}_frame_#{frame}_orf_#{oi}"

#        check_coords(entry.naseq,orf,frame,position_start,position_end)

        # Output in fasta format
        # start and end positions are always relative to the forward strand

        outfile.write(">#{ncbi_accession} #{position_start}|#{position_end}\n#{orf}\n")

      end
      position += orf.length*3+3
    end

  end
end



