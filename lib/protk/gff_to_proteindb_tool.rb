#
# This file is part of protk
# Created by Ira Cooke 9/3/2017
#
# Provides common functionality used by tools that convert gff to a protein database
# 
# These tools read a gff and then write out protein entries in the following format
#
# >lcl|<scaffold_id>_<orientation>_<transcript_id> gene_start|gene_end cds1_start|cds1_end cds2_start|cds2_end ...
#

require 'optparse'
require 'pathname'
require 'protk/tool'

class GffToProteinDBTool < Tool

  attr_accessor :print_progress

  # Initializes commandline options common to all such tools.
  # Individual search tools can add their own options, but should use Capital letters to avoid conflicts
  #
  def initialize(option_support=[])
    super(option_support)

    if ( option_support.include? :add_transcript_info )
      add_boolean_option(:add_transcript_info,false,['--info','Include CDS Coordinates'])
    end

    @option_parser.summary_width=40

    @capturing_gene=false
    @current_gene=nil
  end

  def start_new_gene(line)
    if (line =~ /maker\sgene/)
        new_gene = line.match(/ID=([^;]+)/).captures[0]
        if new_gene!=@current_gene
          @current_gene=new_gene
          return true
        end
      end
  end

  def get_lines_matching(pattern,gene_lines)
    match_lines=[]
    gene_lines.each do |line|  
      if line =~ pattern
        match_lines << line
      end
    end
    match_lines
  end

end