#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 13/3/2012
#
# Manage named protein databases
#
#

require 'protk/constants'
require 'protk/manage_db_tool'
require 'yaml'
require 'pp'




command=ARGV[0]
ARGV[0] = "--help" if ( command==nil || command=="-h" || command=="help")
tool=ManageDBTool.new(command)
if ( tool.option_parser.banner=="")
  tool.option_parser.banner = "Manage named protein databases.\nUsage: manage_db.rb <command> [options] dbname\nCommands are: add remove update list help\nType manage_db <command> -h to get help on a specific command"
end

tool.option_parser.parse!
if ( ARGV[0]=="--help")
  exit
end

command=ARGV.shift
dbname=ARGV.shift

if ( dbname!=nil)
  dbname=dbname.downcase
  throw "Database name should contain no spaces" if ( dbname=~/\s/)
end

genv=Constants.new()


case command
when "add"
  throw "Must specify a database name" if dbname==nil 
  throw "all is a reserved word and cannot be used as a database name" if ( dbname=="all")
  throw "Database #{dbname} exists. Use --update-spec to overwrite." if genv.dbexist?(dbname) && !tool.update_spec
  throw "Database #{dbname} cannot be updated because it doesn't exist" if !genv.dbexist?(dbname) && tool.update_spec

  dbspec = tool.get_predefined_definition dbname
  throw "#{dbname} is not a predefined database"  if tool.predefined && dbspec=={}

  genv.log("Adding new database #{dbname}",:info) if !tool.update_spec
  genv.log("Updating spec for #{dbname}",:info) if tool.update_spec

  if dbspec=={} 
     # Create the database specifiation dictionary (or make ammendments if a predefinition was used)
     dbspec[:is_annotation_db]=tool.is_annotation_db
     dbspec[:sources]=tool.sources
     dbspec[:make_blast_index]= tool.make_blast_index
     dbspec[:make_msgf_index]= tool.make_msgf_index
     dbspec[:include_filters]= tool.is_annotation_db ? [] : tool.include_filters
     dbspec[:id_regexes]= tool.is_annotation_db ? [] : tool.id_regexes
     dbspec[:decoys]= tool.is_annotation_db ? false : tool.decoys
     dbspec[:archive_old]= tool.is_annotation_db ? false : tool.archive_old
     dbspec[:decoy_prefix]= tool.decoy_prefix
     dbspec[:format] = tool.db_format
  end  
  tool.add dbspec, dbname

when "update"
  throw "Must specify a database name" if dbname==nil
  if ( dbname=="all" )
    dbnames=tool.all_database_names(genv)
  else
    dbnames=[dbname]
  end
  p dbnames
  dbnames.each { |db|  
    throw "Database #{db} does not exist" if !genv.dbexist?(db) 
    dbdir="#{genv.protein_database_root}/#{db}"
    throw "Could not find required spec file #{dbdir}/.protkdb.yaml" unless Pathname.new("#{dbdir}/.protkdb.yaml").exist?
   runner=CommandRunner.new(genv)
    runner.run_local("rake -f #{tool.rakefile_path} #{db} ")
  } 
when "list"
  
  gw_file_handle=nil
  if tool.galaxy_write
    pepxml_loc = "#{genv.galaxy_root}/tool-data/pepxml_databases.loc"
    if ( Pathname.new(pepxml_loc).exist?  )
      gw_file_handle=File.open(pepxml_loc,'w')
    end
    p "Warning: Could not find database loc file #{pepxml_loc}" unless Pathname.new(pepxml_loc).exist?
  end
  
  
  Dir.foreach(genv.protein_database_root) do |db_subdir|
    db_specfile="#{genv.protein_database_root}/#{db_subdir}/.protkdb.yaml"
    if ( Pathname.new(db_specfile).exist?)
      spec=YAML.load_file(db_specfile)
      case
      when tool.galaxy || tool.galaxy_write
        unless ( spec[:is_annotation_db] )
          db_prettyname=db_subdir.gsub(/_/,' ').capitalize
          loc_line= "#{db_prettyname}\t#{db_subdir}_\t#{db_subdir}\t#{db_subdir}_\n"
          puts loc_line
          if ( gw_file_handle )
            gw_file_handle.write loc_line
          end
        end
      when tool.verbose
        puts "-- #{db_subdir} --\n"
        PP.pp(spec)
        puts "\n"
      else
        puts "#{db_subdir}\n"
      end
    end
  end

  gw_file_handle.close if ( gw_file_handle)

end

