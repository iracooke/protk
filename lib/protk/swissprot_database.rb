require 'rubygems'
require 'bio'
require 'protk/constants'
require 'pathname'

# Provides fast indexed access to a swissprot database in a flat .dat file
#
class SwissprotDatabase 
  
  def initialize(datfile_path,skip_indexing=false)

    dbpath=Pathname.new(datfile_path)
    dbclass=Bio::SPTR

    unless skip_indexing
      parser = Bio::FlatFileIndex::Indexer::Parser.new(dbclass, nil, nil)
      Bio::FlatFileIndex::Indexer::makeindexFlat(dbpath.realpath.dirname.to_s, parser, {}, \
        dbpath.realpath.to_s)
    end
      
    @db_object=Bio::FlatFileIndex.new("#{dbpath.realpath.dirname.to_s}")
    
    @db_object.always_check_consistency=false
  end
    
  
  def get_entry_for_name(name)
    result=@db_object.get_by_id(name)
    if result==""
      return nil
    else
      Bio::SPTR.new(result)
    end
  end
  
end