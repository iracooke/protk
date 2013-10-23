require 'rubygems'
require 'bio'
require 'protk/constants'
require 'pathname'

# Provides fast indexed access to a swissprot database in a flat .dat file
#
class SwissprotDatabase 
  
  def initialize(env=nil,database="swissprot")
    if ( env!=nil)
      @genv=env
    else
      @genv=Constants.new
    end


    dbpath=Pathname.new(database)

    if ( dbpath.exist? )
#      require 'debugger';debugger
      dbclass=Bio::SPTR
      parser = Bio::FlatFileIndex::Indexer::Parser.new(dbclass, nil, nil)
      Bio::FlatFileIndex::Indexer::makeindexFlat(dbpath.realpath.dirname.to_s, parser, {}, dbpath.realpath.to_s)
      @db_object=Bio::FlatFileIndex.new("#{dbpath.realpath.dirname.to_s}")
    elsif ( database=="swissprot")
      @db_object=Bio::FlatFileIndex.new("#{@genv.protein_database_root}/#{@genv.uniprot_sprot_annotation_database}")
    else
      @db_object=Bio::FlatFileIndex.new("#{@genv.protein_database_root}/#{@genv.uniprot_trembl_annotation_database}")
    end
    
    @db_object.always_check_consistency=false
  end
    
  
  def get_entry_for_name(name)
    result=@db_object.get_by_id(name)
    if result==""
      if ( @genv!=nil)
        @genv.log("Failed to find UniProt entry for protein named #{name} in database",:warn)
      end
      return nil
    else
      Bio::SPTR.new(result)
    end
  end
  
end