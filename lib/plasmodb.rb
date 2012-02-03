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

    database_file="#{@genv.protein_database_root}/plasmodb_data/PfalciparumGene_PlasmoDB-8.0.txt"

    throw "The plasmodb database at \"#{database_file}\" does not exist"  if ( database_file==nil || !FileTest.exist?(database_file) )

    @db_object=EuPathDBGeneInformationFileExtractor.new(database_file)

  end


    def get_entry_for_name(name)
      
      @genv.log("Getting entry for #{name}",:info)
      
      begin
        result=nil 
        result=@db_object.extract_gene_info(name,10000)
        
      rescue
        
        
        if result==nil
          if ( @genv!=nil)
            @genv.log("Failed to find PlasmoDB entry for gene named #{name} in database",:warn)
          end
        end
        
        
        return result
      end
        
        
    end
  
end