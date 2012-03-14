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
      
      @options.db_sources=[]
      @option_parser.on( '--db-source dbname', 'A named database to use an an input source. Multiple db sources may be specified' ) do  |db|
        @options.db_sources.push db
      end
      
      @options.file_sources=[]
      @option_parser.on( '--file-source fs', 'A file path to a fasta file to use as an input source. Multiple file sources may be specified' ) do  |fs|
        @options.file_sources.push fs
      end

      @options.ftp_sources=[]
      @option_parser.on( '--ftp-source fs', 'A space separated pair of urls. The first is an ftp url to a fasta file to use as an input source. The second is an ftp url to release notes file or other file which can be checked to see if the database requires an update. Multiple ftp sources may be specified' ) do  |ftps|
        
        
        @options.ftp_sources.push ftps.split(/ /)
      end

      @options.include_filters=[]
      @option_parser.on( '--include-filters rx', 'A comma separated series of regular expressions to use as filters. Each time this argument is encountered is adds a set of filters for another source file, in the order that source files were added' ) do  |tx|

        throw "Specified include filter #{tx} is not in the format /regex1/,/regex2/" unless match=tx.match(/\/(.*)\//)
        tx= match[1]

        @options.include_filters.push tx.split(/\/,\//)
      end
      
      @options.update_spec=false
      @option_parser.on( '--update-spec', 'Change the specification for an existing database by updating its spec file' ) do  
        @options.update_spec=true
      end

      @option_parser.banner = "Add new protein databases.\nUsage: manage_db.rb add [options] <dbname>"

    when "list"
      @option_parser.banner = "List protein databases.\nUsage: manage_db.rb list"
    when "update"
      @option_parser.banner = "Update protein databases.\nUsage: manage_db.rb update <dbname>"
    end
    
  end

end