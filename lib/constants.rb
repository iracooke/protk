# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Initialises global constants. 
# All tools should source this file.
#
require 'yaml'
require 'logger'
require 'pathname'

class Constants

  # A Hash holding all the constants
  #
  attr :env
  
  # These are logger attributes with thresholds as indicated
  #  DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
  #Debug (development mode) or Info (production)
  #
  attr :stdout_logger 
  
  #Warn
  #
  attr :file_logger 




  # Provides direct access to constants through methods of the same name
  #
  def method_missing(method)
    @env[method.to_s]
  end




  # Read the global constants file and initialize our class @env variable
  # Initialize loggers
  #
  def initialize
        
    config_yml = YAML.load_file "#{File.dirname(__FILE__)}/../config.yml"


    throw "Unable to read the config file at #{File.dirname(__FILE__)}/../config.yml" unless config_yml!=nil

    run_setting=config_yml['run_setting']    
    throw "No run_setting found in config file" unless run_setting!=nil

    @env=config_yml[run_setting]    
    throw "No data found for run setting #{run_setting} in config file" unless @env!=nil

    @stdout_logger=Logger.new(STDOUT)
    @file_logger=Logger.new(@env['log_file'],'daily')

    throw "Unable to create file logger at path #{@env['log_file']}" unless @file_logger!=nil
    throw "Unable to create stdout logger " unless @stdout_logger!=nil

  
    info_level=config_yml['message_level']

    case info_level
    when "info"
      @stdout_logger.level=Logger::INFO
    when "debug"    
      @stdout_logger.level=Logger::DEBUG
    when "warn"
      @stdout_logger.level=Logger::WARN      
    end
    
  end




  # Write a message to all logger objects
  #
  def log(message,level)
    @stdout_logger.send(level,message)
    @file_logger.send(level,message)        
  end



  # Based on the database shortname and global database path, find the most current version of the required database
  # This function returns the path of the database with an extension appropriate to the database type
  # Always returns a valid database or throws an error
  #
  def current_database_for_name_and_type(dbname,db_type,db_suffix="")
    dbroot=self.tpp_protein_dbroot
    
    # Remove any trailing slashes or spaces from the end of dbroot if present
    #
    dbroot.sub!(/(\/*\s*)$/,"")
    
    current_dbroot=Pathname.new("#{dbroot}/#{dbname}")
    throw "Error: Specified database #{current_dbroot.to_s} does not exist" unless current_dbroot.exist?
    

    candidates=current_dbroot.children
    
    # Filter candidates with the right filenames
    #
    candidates = candidates.find_all { |dbpath|
      dbstring=dbpath.basename.to_s
      /#{dbname}_(\d+)#{db_suffix}\./i.match(dbstring)!=nil
    }
    
    dates=candidates.collect { |dbpath| 
       dbstring=dbpath.basename.to_s
       m=/#{dbname}_(\d+)#{db_suffix}\./i.match(dbstring)
       m[1].to_i
     }
     
     maxdate=dates[0]
     dates.each { |d| 
       if ( d > maxdate )
         maxdate=d
       end
     }
     extension=""
     case db_type
     when :fasta
       extension=".fasta"
     end

     # Enabling this will force a transition to a new db naming scheme. Better one though
     #
     #   "#{dbroot}/#{dbname.downcase}/#{dbname.downcase}_#{maxdate}_DECOY#{extension}"

          
     "#{dbroot}/#{dbname}/#{dbname.downcase}_#{maxdate}#{db_suffix}#{extension}"
   end



end