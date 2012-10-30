#
# This file is part of protk
# Created by Ira Cooke 13/3/2012
#
# Provides support for the manage_db tool
#

require 'optparse'
require 'ostruct'
require 'protk/tool'

class ManageDBTool < Tool

  def add dbspec, dbname
    genv=Constants.new()
    dbdir="#{genv.protein_database_root}/#{dbname}"
    %x[mkdir -p #{dbdir}]

    File.open("#{dbdir}/.protkdb.yaml", "w") {|file| file.puts(dbspec.to_yaml) }
  end

  def predefined_databases_help
    this_dir=File.dirname(__FILE__)
    definition_files=Dir.glob("#{this_dir}/data/predefined_db.*")
    help_string=""
    for fn in definition_files
      name=Pathname.new(fn).basename.to_s.split(".")[1]
      desc=YAML.load(File.read(fn))[:description]
      help_string << "\t\t\t\t\t#{name} : #{desc}\n"
    end

    help_string
  end

  def predefined_names
    this_dir=File.dirname(__FILE__)
    definition_files=Dir.glob("#{this_dir}/data/predefined_db.*")
    definition_files.collect { |fn| Pathname.new(fn).basename.to_s.split(".")[1] }
  end

  def get_predefined_definition name
    this_dir=File.dirname(__FILE__)
    filename="#{this_dir}/data/predefined_db.#{name}.yaml"
    return {} unless Pathname.new(filename).exist?
    if predefined_names.include? name
      return YAML.load(File.read(filename))
    end
    return {}
  end


  def all_database_names(genv)
    all_names=[]
    Dir.foreach(genv.protein_database_root) do |db_subdir|
      db_specfile="#{genv.protein_database_root}/#{db_subdir}/.protkdb.yaml"
      if ( Pathname.new(db_specfile).exist?)
        all_names.push db_subdir
      end
    end
    return all_names
  end

  def rakefile_path
    "#{File.dirname(__FILE__)}/manage_db_rakefile.rake"
  end

  # Initializes the commandline options
  def initialize(command)
    super({:help=>false})

    @option_parser.banner=""


    case command
    when "add"          
      
      @options.sources=[]

      @options.predefined=false
      @option_parser.on( '--predefined', "Install a database from one of protk\'s predefined definitions.\n\t\t\t\t\tAvailable definitions are;\n#{predefined_databases_help}" ) do 
        @options.predefined=true
      end
      
      @option_parser.on( '--db-source dbname', 'A named database to use an an input source. Multiple db sources may be specified' ) do  |db|
        @options.sources.push db
      end
      
      @option_parser.on( '--file-source fs', 'A file path to a fasta file to use as an input source. Multiple file sources may be specified' ) do  |fs|
        @options.sources.push fs
      end

      @option_parser.on( '--ftp-source fs', "A space separated pair of urls. \n\t\t\t\t\tThe first is an ftp url to a fasta file to use as an input source.\n\t\t\t\t\tThe second is an ftp url to release notes file or other file which can be checked to see if the database requires an update. If no such url exists type \"none\" \n\t\t\t\t\tMultiple ftp sources may be specified" ) do  |ftps|
        @options.sources.push ftps.split(/\s+/)
      end

      @options.include_filters=[]
      @option_parser.on( '--include-filters rx', "A comma separated series of regular expressions to use as filters. \n\t\t\t\t\tEach time this argument is encountered is adds a set of filters for another source file, in the order that source files were added. \n\t\t\t\t\tIf you use multiple source files you will need multiple --include-filters" ) do  |tx|

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

      @options.make_msgf_index=false
      @option_parser.on( '--make-msgf-index', 'Create an index suitable for msgf plus (required for msgfplus searches)' ) do  
        @options.make_msgf_index=true
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

      @options.is_annotation_db=false
      @option_parser.on( '--annotation-db', 'This database is not for searching but for annotating search results (eg Swissprot .dat file)' ) do  
        @options.is_annotation_db=true
      end

      @options.db_format="fasta"
      @option_parser.on( '--db-format format', 'Format of the database file (fasta or dat). Default is fasta' ) do  |format|
        @options.db_format=format
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