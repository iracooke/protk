require 'rubygems'
require 'bio'
require 'constants'
require 'eupathdb_gene_information_table'

# Provides fast indexed access to a swissprot database in a flat .dat file
#
class PlasmoDB
  
  def initialize(env=nil)
    if ( env!=nil)
      @genv=env
    else
      @genv=Constants.new
    end

    throw "The plasmodb database at \"#{@genv.plasmodb_dat}\" does not exist"  if ( @genv.plasmodb_dat==nil || !FileTest.exist?(@genv.plasmodb_dat) )

    @db_object=EuPathDBGeneInformationFileExtractor.new(@genv.plasmodb_dat)

  end


    def get_entry_for_name(name)
      result=@db_object.extract_gene_info(name,10000)
      if result==nil
        if ( @genv!=nil)
          @genv.log("Failed to find PlasmoDB entry for gene named #{name} in database",:warn)
        end
        return nil
      else
        return result
      end
    end
  
end