#
# This file is part of protk
# Created by Ira Cooke 16/12/2010
#
# Provides common functionality used by xinteract tools provided by the TPP. Includes PeptideProphet, InterProphet and ProteinProphet
#

require 'optparse'
require 'ostruct'
require 'pathname'
require 'libxml'
require 'protk/search_tool'

class ProphetTool < SearchTool

  include LibXML


  # Initializes the commandline options
  def initialize(option_support=[:prefix,:over_write])
    
    super(option_support)

    if ( option_support.include? :probability_threshold )
      add_value_option(:probability_threshold,0.05,['--p-thresh val', 'Probability threshold below which PSMs are discarded'])
    end

  end
   
  # TODO: Deal with multiple enzyme combos
  #
  def self.xinteract_code_for_enzyme(enzyme_name)

  	codes = {
  		'trypsin' => 'T',
  		'stricttrypsin' => 'S',
  		'chymotrypsin' => 'C',
  		'ralphtrypsin' => 'R',
  		'aspn' => 'A',
  		'gluc' => 'G',
  		'glucbicarb' => 'B',
  		'cnbr' => 'M',
  		'elastase' => 'E',
  		'lysn' => 'L',
  		'nonspecific' => 'N'
  	}
  	codes[enzyme_name]

  end

end