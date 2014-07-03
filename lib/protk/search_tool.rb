#
# This file is part of protk
# Created by Ira Cooke 15/12/2010
#
# Provides common functionality used by all msms search tools.
#
# It allows;
# 1. Specification of the search database using a simple name ... this class provides the necessary search for the actual file
# 2. Output files to be specified via a prefix or suffix to be added to the name of the corresponding input file
# 

require 'optparse'
require 'pathname'
require 'protk/tool'

class SearchTool < Tool

  # Initializes commandline options common to all search tools.
  # Individual search tools can add their own options, but should use Capital letters to avoid conflicts
  #
  def initialize(option_support=[])
    super(option_support)

    # if (option_support.include? :database)
    #   add_value_option(:database,"sphuman",['-d', '--database dbname', 'Specify the database to use for this search. Can be a named protk database or the path to a fasta file'])        
    # end
    
    if ( option_support.include? :enzyme )
      add_value_option(:enzyme,"Trypsin",['--enzyme enz', 'Enzyme'])
    end

    if ( option_support.include? :modifications )
      add_value_option(:var_mods,"",['--var-mods vm','Variable modifications. These should be provided in a comma separated list'])
      add_value_option(:fix_mods,"",['--fix-mods fm','Fixed modifications. These should be provided in a comma separated list'])
    end

    if ( option_support.include? :instrument )
      add_value_option(:instrument,"ESI-QUAD-TOF",['--instrument instrument', 'Instrument'])
    end

    if ( option_support.include? :mass_tolerance_units )
      add_value_option(:fragment_tolu,"Da",['--fragment-ion-tol-units tolu', 'Fragment ion mass tolerance units (Da or mmu). Default=Da'])      
      add_value_option(:precursor_tolu,"ppm",['--precursor-ion-tol-units tolu', 'Precursor ion mass tolerance units (ppm or Da). Default=ppm'])
    end

    if ( option_support.include? :mass_tolerance )
      add_value_option(:fragment_tol,0.65,['-f', '--fragment-ion-tol tol', 'Fragment ion mass tolerance (unit dependent). Default=0.65'])
      add_value_option(:precursor_tol,200,['-p','--precursor-ion-tol tol', 'Precursor ion mass tolerance. Default=200'])
    end
    
    if ( option_support.include? :precursor_search_type )
      add_value_option(:precursor_search_type,"monoisotopic",['-a', '--search-type type', 'Use monoisotopic or average precursor masses. (monoisotopic or average)'])
    end

    if ( option_support.include? :strict_monoisotopic_mass )
      add_boolean_option(:strict_monoisotopic_mass,false,['-s', '--strict-monoisotopic-mass', 'Dont allow for misassignment of monoisotopic mass to another isotopic peak'])
    end

    if ( option_support.include? :missed_cleavages )
      add_value_option(:missed_cleavages,2,['-v', '--num-missed-cleavages num', 'Number of missed cleavages allowed'])
    end

    if ( option_support.include? :cleavage_semi )
      add_boolean_option(:cleavage_semi,false,['--cleavage-semi', 'Search for peptides with up to 1 non-enzymatic cleavage site'])
    end

    if ( option_support.include? :respect_precursor_charges )
      add_boolean_option(:respect_precursor_charges,false,['-q', '--respect-charges','Dont respect charges in the input file. Instead impute them by trying various options'])
    end

    if ( option_support.include? :searched_ions )
      add_value_option(:searched_ions,"",['--searched-ions si', 'Ion series to search (default=b,y)'])
    end

    if ( option_support.include? :multi_isotope_search )
      add_boolean_option(:multi_isotope_search,false,["--multi-isotope-search","Expand parent mass window to include windows around neighbouring isotopic peaks"])
    end

    if ( option_support.include? :num_peaks_for_multi_isotope_search )
      add_value_option(:num_peaks_for_multi_isotope_search,0,["--num-peaks-for-multi-isotope-search np","Number of peaks to include in multi-isotope search"])
    end

    if ( option_support.include? :glyco)
      add_boolean_option(:glyco,false,['-g','--glyco', 'Expect N-Glycosylation modifications as variable mod in a search or as a parameter when building statistical models'])
    end

    if ( option_support.include? :acetyl_nterm)
      add_boolean_option(:acetyl_nterm,false,['-y','--acetyl-nterm', 'Expect N-terminal acetylation as a variable mod in a search or as a parameter when building statistical models'])
    end

    if ( option_support.include? :methionine_oxidation)
      add_boolean_option(:methionine_oxidation,false,['-m', '--methionineo', 'Expect Oxidised Methionine modifications as variable mod in a search'])
    end

    if ( option_support.include? :carbamidomethyl)
      add_boolean_option(:carbamidomethyl,false,['-c', '--carbamidomethyl', 'Expect Carbamidomethyl C modifications as fixed mod in a search'])
    end
    
    if ( option_support.include? :maldi)
      add_boolean_option(:maldi,false,['-l', '--maldi', 'Run a search on MALDI data'])
    end

    @option_parser.summary_width=40

      
  end
      

end



