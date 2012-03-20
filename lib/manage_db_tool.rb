#
# This file is part of protk
# Created by Ira Cooke 13/3/2012
#
# Provides support for the manage_db tool
#

require 'optparse'
require 'ostruct'
require 'tool'

class ManageDBTool < Tool

  # Initializes the commandline options
  def initialize(command)
    super({:help=>false})

    @option_parser.banner=""


    case command
    when "add"          
      
      @options.sources=[]
      
      @option_parser.on( '--db-source dbname', 'A named database to use an an input source. Multiple db sources may be specified' ) do  |db|
        @options.sources.push db
      end
      
      @option_parser.on( '--file-source fs', 'A file path to a fasta file to use as an input source. Multiple file sources may be specified' ) do  |fs|
        @options.sources.push fs
      end

      @option_parser.on( '--ftp-source fs', 'A space separated pair of urls. The first is an ftp url to a fasta file to use as an input source. The second is an ftp url to release notes file or other file which can be checked to see if the database requires an update. Multiple ftp sources may be specified' ) do  |ftps|
        @options.sources.push ftps.split(/\s+/)
      end

      @options.include_filters=[]
      @option_parser.on( '--include-filters rx', 'A comma separated series of regular expressions to use as filters. Each time this argument is encountered is adds a set of filters for another source file, in the order that source files were added' ) do  |tx|

        throw "Specified include filter #{tx} is not in the format /regex1/,/regex2/" unless match=tx.match(/\/(.*)\//)
        tx= match[1]

        @options.include_filters.push tx.split(/\/,\//)
      end
      
      @options.id_regexes=[]
      @option_parser.on( '--id-regex rx', 'A regular expression with a single capture group for capturing the protein ID from a faster description line' ) do  |rx|
        rx.gsub!(/^\//,'')
        rx.gsub!(/\/$/,'')
        @options.id_regexes.push rx
      end
      
      @options.make_blast_index=false
      @option_parser.on( '--make-blast-index', 'Create a blast index of the database (required for OMSSA searches)' ) do  
        @options.make_blast_index=true
      end      

      @options.decoys=false
      @option_parser.on( '--add-decoys', 'Add random sequences to be used as decoys to the database (required for OMSSA searches)' ) do  
        @options.decoys=true
      end      

      @options.archive_old=false
      @option_parser.on( '--archive-old', 'Don\'t delete old fasta files when updating to a newer version' ) do  
        @options.archive_old=true
      end

      @options.decoy_prefix="decoy_"
      @option_parser.on( '--decoy-prefix pref', 'Define a prefix string to prepend to protein ID\'s used as decoys' ) do  |pref|
        @options.decoy_prefix=pref
      end      

      
      @options.update_spec=false
      @option_parser.on( '--update-spec', 'Change the specification for an existing database by updating its spec file' ) do  
        @options.update_spec=true
      end

      @option_parser.banner = "Add new protein databases.\nUsage: manage_db.rb add [options] <dbname>"

    when "list"
      @option_parser.banner = "List protein databases.\nUsage: manage_db.rb list"
      
      @options.verbose=false
      @option_parser.on('-v', '--verbose', 'Display detailed specification for each installed database' ) do  
        @options.verbose=true
      end
      
      @options.galaxy=false
      @option_parser.on('-g' ,'--generate-loc-file', 'Generate a galaxy loc file' ) do  
        @options.galaxy=true
      end

      @options.galaxy_write=false
      @option_parser.on('-G' ,'--write-loc-file', 'Update the pepxml_databases.loc file in galaxy if a galaxy_root directory has been configured and the file exists' ) do  
        @options.galaxy_write=true
      end
      
      
    when "update"
      @option_parser.banner = "Update protein databases.\nUsage: manage_db.rb update <dbname>"
    end
    
  end

end