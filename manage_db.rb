#
# This file is part of protk
# Created by Ira Cooke 13/3/2012
#
# Manage named protein databases
#
#


#!/bin/sh
# -------+---------+---------+-------- + --------+---------+---------+---------+
#     /  This section is a safe way to find the interpretter for ruby,  \
#    |   without caring about the user's setting of PATH.  This reduces  |
#    |   the problems from ruby being installed in different places on   |
#    |   various operating systems.  A much better solution would be to  |
#    |   use  `/usr/bin/env -S-P' , but right now `-S-P' is available    |
#     \  only on FreeBSD 5, 6 & 7.                        Garance/2005  /
# To specify a ruby interpreter set PROTK_RUBY_PATH in your environment. 
# Otherwise standard paths will be searched for ruby
#
if [ -z "$PROTK_RUBY_PATH" ] ; then
  
  for fname in /usr/local/bin /opt/csw/bin /opt/local/bin /usr/bin ; do
    if [ -x "$fname/ruby" ] ; then PROTK_RUBY_PATH="$fname/ruby" ; break; fi
  done
  
  if [ -z "$PROTK_RUBY_PATH" ] ; then
    PROTK_RUBY_PATH=`which ruby`
#    echo "Unable to find a 'ruby' interpretter!"   >&2
#    exit 1
  fi
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

require 'constants'
require 'yaml'
require 'manage_db_tool'
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

dbdir="#{genv.protein_database_root}/#{dbname}"

case command
when "add"
  throw "Must specify a database name" if dbname==nil 
  throw "Database #{dbname} exists" if genv.dbexist?(dbname) && !tool.update_spec
  throw "Database #{dbname} cannot be updated because it doesn't exist" if !genv.dbexist?(dbname) && tool.update_spec

  genv.log("Adding new database #{dbname}",:info) if !tool.update_spec
  genv.log("Updating spec for #{dbname}",:info) if tool.update_spec

  # Create the database specifiation dictionary
  dbspec={}
#  dbspec[:ftp_sources]=tool.ftp_sources
#  dbspec[:file_sources]=tool.file_sources
#  dbspec[:db_sources]=tool.db_sources
  dbspec[:include_filters]=tool.include_filters
  dbspec[:id_regexes]=tool.id_regexes
  dbspec[:make_blast_index]=tool.make_blast_index
  dbspec[:decoys]=tool.decoys
  dbspec[:archive_old]=tool.archive_old
  dbspec[:decoy_prefix]=tool.decoy_prefix
  dbspec[:sources]=tool.sources

  # Create the database directory
  Dir.mkdir(dbdir) unless tool.update_spec

  File.open("#{dbdir}/.protkdb.yaml", "w") {|file| file.puts(dbspec.to_yaml) }

when "update"
  throw "Must specify a database name" if dbname==nil 
  throw "Database #{dbname} does not exist" if !genv.dbexist?(dbname) 

  throw "Could not find required spec file #{dbdir}/.protkdb.yaml" unless Pathname.new("#{dbdir}/.protkdb.yaml").exist?
  runner=CommandRunner.new(genv)
  runner.run_local("rake -f manage_db_rakefile.rake #{dbname}")

when "list"
  
  gw_file_handle=nil
  if tool.galaxy_write
    pepxml_loc = "#{genv.galaxy_root}/tool-data/pepxml_databases.loc"
    if ( Pathname.new(pepxml_loc).exist?  )
      gw_file_handle=File.open(pepxml_loc,'w')
    end
    throw "Could not find database loc file #{pepxml_loc}" unless Pathname.new(pepxml_loc).exist?
  end
  
  
  Dir.foreach(genv.protein_database_root) do |db_subdir|
    db_specfile="#{genv.protein_database_root}/#{db_subdir}/.protkdb.yaml"
    if ( Pathname.new(db_specfile).exist?)
      spec=YAML.load_file(db_specfile)
      case
      when tool.galaxy || tool.galaxy_write
        db_prettyname=db_subdir.gsub(/_/,' ').capitalize
        loc_line= "#{db_prettyname}\t#{db_subdir}_\t#{db_subdir}\t#{db_subdir}_\n"
        puts loc_line
        if ( gw_file_handle )
          gw_file_handle.write loc_line
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

