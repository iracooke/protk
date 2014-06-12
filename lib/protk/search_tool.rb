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

class FastaDatabase
  attr :name
  attr :path
  def initialize(name,path)
    @name=name
    @path=path
  end
end

class SearchTool < Tool

  # Initializes commandline options common to all search tools.
  # Individual search tools can add their own options, but should use Capital letters to avoid conflicts
  #
  def initialize(option_support=[])
    super(option_support)

    if (option_support.include? :database)          
      @options.database = "sphuman"
      @option_parser.on( '-d', '--database dbname', 'Specify the database to use for this search. Default=sphuman' ) do |dbname|
        options.database = dbname
      end

    end
    
    if ( option_support.include? :enzyme )
      add_value_option(:enzyme,"Trypsin",['--enzyme enz', 'Enzyme'])
    end

    if ( option_support.include? :modifications )
      add_value_option(:var_mods,"",['--var-mods vm','Variable modifications. These should be provided in a comma separated list'])
      add_value_option(:fix_mods,"",['--fix-mods fm','Fixed modifications. These should be provided in a comma separated list'])
    end

    if ( option_support.include? :instrument )
      @options.instrument = "ESI-QUAD-TOF"
      @option_parser.on('--instrument instrument', 'Instrument') do |instrument|
       @options.instrument=instrument
     end
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
      @options.precursor_search_type="monoisotopic"
      @option_parser.on( '-a', '--search-type type', 'Use monoisotopic or average precursor masses. (monoisotopic or average)' ) do |type| 
        @options.precursor_search_type = type
      end
    end

    if ( option_support.include? :strict_monoisotopic_mass )
      @options.strict_monoisotopic_mass=false
      @option_parser.on( '-s', '--strict-monoisotopic-mass', 'Dont allow for misassignment of monoisotopic mass to another isotopic peak') do
        @options.strict_monoisotopic_mass=true
      end
    end

    if ( option_support.include? :missed_cleavages )
      add_value_option(:missed_cleavages,2,['-v', '--num-missed-cleavages num', 'Number of missed cleavages allowed'])
    end

    if ( option_support.include? :cleavage_semi )
      add_boolean_option(:cleavage_semi,false,['--cleavage-semi', 'Search for peptides with up to 1 non-enzymatic cleavage site'])
    end

    if ( option_support.include? :respect_precursor_charges )
      @options.respect_precursor_charges=false
      @option_parser.on( '-q', '--respect-charges','Dont respect charges in the input file. Instead impute them by trying various options') do 
        @options.respect_precursor_charges=true
      end
    end

    if ( option_support.include? :searched_ions )
        @options.searched_ions = ""
        @option_parser.on('--searched-ions si', 'Ion series to search (default=b,y)' ) do |si|
          @options.searched_ions = si
        end
    end

    if ( option_support.include? :multi_isotope_search )
      add_boolean_option(:multi_isotope_search,false,["--multi-isotope-search","Expand parent mass window to include windows around neighbouring isotopic peaks"])
    end

    if ( option_support.include? :num_peaks_for_multi_isotope_search )
        @options.num_peaks_for_multi_isotope_search="0"
        @option_parser.on("--num-peaks-for-multi-isotope-search np","Number of peaks to include in multi-isotope search") do |np|
          @options.num_peaks_for_multi_isotope_search=np
        end
    end

    if ( option_support.include? :glyco)
      add_boolean_option(:glyco,false,['-g','--glyco', 'Expect N-Glycosylation modifications as variable mod in a search or as a parameter when building statistical models'])
    end

    if ( option_support.include? :methionine_oxidation)
      add_boolean_option(:methionine_oxidation,false,['-m', '--methionineo', 'Expect Oxidised Methionine modifications as variable mod in a search'])
      # @options.methionine_oxidation = false
      # @option_parser.on( '-m', '--methionineo', 'Expect Oxidised Methionine modifications as variable mod in a search' ) do 
      #   @options.methionine_oxidation = true
      # end
    end

    if ( option_support.include? :carbamidomethyl)
      @options.carbamidomethyl = false
      @option_parser.on( '-c', '--carbamidomethyl', 'Expect Carbamidomethyl C modifications as fixed mod in a search' ) do 
        @options.carbamidomethyl = true
      end
    end
    
    if ( option_support.include? :maldi)
      @options.maldi=false
      @option_parser.on( '-l', '--maldi', 'Run a search on MALDI data') do
        @options.maldi=true
      end
    end

    @option_parser.summary_width=40

      
  end
  
  
  def jobid_from_filename(filename)
    jobid="protk"
    jobnum_match=filename.match(/(.{1,10}).*?\./)
    if (jobnum_match!=nil)
      jobid="#{self.jobid_prefix}#{jobnum_match[1]}"
    end
    return jobid
  end
    
  # Based on the database setting and global database path, find the most current version of the required database
  # This function returns the name of the database with an extension appropriate to the database type
  #
  # TODO: Deprecate this
  def current_database(db_type,db=@options.database)
    return Constants.new.current_database_for_name(db)
  end

  # Full path to a fasta database for this search
  # If specified db was a real file it returns the path to that file
  # If a named db it returns the full path to the database for the named db
  #
  # def database_path
  #   case
  #     when Pathname.new(@options.database).exist? # It's an explicitly named db  
  #       db_path=Pathname.new(@options.database).realpath.to_s
  #     else
  #       db_path=Constants.new.current_database_for_name @options.database
  #   end
  #   db_path
  # end

  def database_info
    case
      when Pathname.new(@options.database).exist? # It's an explicitly named db  
        db_path=Pathname.new(@options.database).realpath.to_s
        db_name=Pathname.new(@options.database).basename.to_s
      else
        db_path=Constants.new.current_database_for_name @options.database
        db_path=@options.database
    end
    FastaDatabase.new(db_name,db_path)
  end

end



