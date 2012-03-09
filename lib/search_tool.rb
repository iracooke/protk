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
require 'tool'

class SearchTool < Tool

  # Initializes commandline options common to all search tools.
  # Individual search tools can add their own options, but should use Capital letters to avoid conflicts
  #
  def initialize(option_support={})
    super(option_support)

    if (option_support[:database]==true)          
          
      @options.database = "sphuman"
      @option_parser.on( '-d', '--database dbname', 'Specify the database to use for this search. Default=sphuman' ) do |dbname|
        options.database = dbname
      end

    end
    
    if ( option_support[:msms_search_detailed_options]==true)      
       @options.allowed_charges="1+,2+,3+"
       @option_parser.on(  '--allowed-charges ac', 'Allowed precursor ion charges. Default=1+,2+,3+' ) do |ac|
         @options.allowed_charges = ac
       end       
       
       @options.enzyme = "Trypsin"
       @option_parser.on('--enzyme enz', 'Enzyme') do |enz|
         @options.enzyme=enz
       end
       
       @options.instrument = "ESI-QUAD-TOF"
       @option_parser.on('--instrument instrument', 'Instrument') do |instrument|
         @options.instrument=instrument
       end
       
       
       @options.var_mods = ""
        @option_parser.on('--var-mods vm', 'Variable modifications (Overrides -g)' ) do |vm|
          @options.var_mods = vm
        end

        @options.fix_mods = ""
        @option_parser.on('--fix-mods fm', 'Fixed modifications (Overrides -c and -m options)' ) do |fm|
          @options.fix_mods = fm
        end

        @options.searched_ions = ""
        @option_parser.on('--searched-ions si', 'Ion series to search (default=b,y)' ) do |si|
          @options.searched_ions = si
        end

        
        @options.fragment_tolu="Da"
        @option_parser.on('--fragment-ion-tol-units tolu', 'Fragment ion mass tolerance units (Da or mmu). Default=Da' ) do |tolu|
          @options.fragment_tolu = tolu
        end
        
        @options.precursor_tolu="ppm"
        @option_parser.on('--precursor-ion-tol-units tolu', 'Precursor ion mass tolerance units (ppm or Da). Default=ppm' ) do |tolu|
          @options.precursor_tolu = tolu
        end
        
        @options.email=""
        @option_parser.on('--email em', 'User email.') do |em|
          @options.email = em
        end

        @options.username=""
        @option_parser.on('--username un', 'Username.') do |un|
          @options.username = un
        end

        @options.num_peaks_for_multi_isotope_search="0"
        @option_parser.on("--num-peaks-for-multi-isotope-search np","Number of peaks to include in multi-isotope search") do |np|
          @options.num_peaks_for_multi_isotope_search=np
        end

       
     end
    
    if ( option_support[:msms_search]==true)      
      @options.fragment_tol=0.65
      @option_parser.on( '-f', '--fragment-ion-tol tol', 'Fragment ion mass tolerance (unit dependent). Default=0.65' ) do |tol|
        @options.fragment_tol = tol
      end
      
      @options.precursor_tol=200
      @option_parser.on( '-p', '--precursor-ion-tol tol', 'Precursor ion mass tolerance in (ppm if precursor search type is monoisotopic or Da if it is average). Default=200' ) do |tol|
        @options.precursor_tol = tol.to_f
      end
      
      @options.respect_precursor_charges=false
      @option_parser.on( '-q', '--respect-charges','Dont respect charges in the input file. Instead impute them by trying various options') do 
        @options.respect_precursor_charges=true
      end
      
      @options.precursor_search_type="monoisotopic"
      @option_parser.on( '-a', '--search-type type', 'Use monoisotopic or average precursor masses. (monoisotopic or average)' ) do |type| 
        @options.precursor_search_type = type
      end
      
      @options.strict_monoisotopic_mass=false
      @option_parser.on( '-s', '--strict-monoisotopic-mass', 'Dont allow for misassignment of monoisotopic mass to another isotopic peak') do
        @options.strict_monoisotopic_mass=true
      end
      
      @options.missed_cleavages=2
      @option_parser.on( '-v', '--num-missed-cleavages num', 'Number of missed cleavages allowed' ) do |num| 
        @options.missed_cleavages = num
      end
    
      @options.carbamidomethyl=true
      @option_parser.on( '-c', '--no-carbamidomethyl', 'Run a search without a carbamidomethyl fixed modification' ) do 
        @options.carbamidomethyl = false
      end

      @options.methionine_oxidation=false
      @option_parser.on( '-m', '--methionine-oxidation', 'Run a search with oxidised methionines as a variable modification' ) do 
        @options.methionine_oxidation = true
      end
      
    end
      
    if ( option_support[:glyco]==true)

      @options.glyco = false
      @option_parser.on( '-g', '--glyco', 'Use N-Glycosylation information' ) do 
        @options.glyco = true
      end

    end
    
    if ( option_support[:maldi]==true)
      @options.maldi=false
      @option_parser.on( '-l', '--maldi', 'Run a search on MALDI data') do
        @options.maldi=true
      end
    end
      
  end
  
  
  def jobid_from_filename(filename)
    jobid="protk"
    jobnum_match=filename.match(/(.{1,10})\.d/)
    if (jobnum_match!=nil)
      jobid="#{self.jobid_prefix}#{jobnum_match[1]}"
    end
    return jobid
  end
    
  # Based on the database setting and global database path, find the most current version of the required database
  # This function returns the name of the database with an extension appropriate to the database type
  #
  def current_database(db_type,db=@options.database)
    return Constants.new.current_database_for_name_and_type(db,db_type)
  end
    
end