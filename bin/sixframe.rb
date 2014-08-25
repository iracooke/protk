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
  end
  if ( orf_from_coords!=aaseq)
    require 'debugger'; debugger
  end
end


tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Create a sixframe translation of a genome.\n\nUsage: sixframe.rb [options] genome.fasta"

tool.add_boolean_option(:print_coords,false,['--coords', 'Write genomic coordinates in the fasta header'])
tool.add_boolean_option(:keep_header,true,['--strip-header', 'Dont write sequence definition'])
tool.add_value_option(:min_len,20,['--min-len','Minimum ORF length to keep'])

exit unless tool.check_options(true)

input_file=ARGV[0]

output_file = tool.explicit_output!=nil ? tool.explicit_output : nil

output_fh = output_file!=nil ? File.new("#{output_file}",'w') : $stdout


file = Bio::FastaFormat.open(input_file)

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
      if ( orf.length > tool.min_len )

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

        defline=">#{ncbi_accession}"

        if tool.print_coords
          defline << " #{position_start}|#{position_end}"
        end

        if tool.keep_header
          defline << " #{entry.definition}"
        end

        # Output in fasta format
        # start and end positions are always relative to the forward strand

        output_fh.write("#{defline}\n#{orf}\n")

      end
      position += orf.length*3+3
    end

  end
end



