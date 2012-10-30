#
# This file is part of protk
# Created by Ira Cooke 16/12/2010
#
# Provides common functionality used by xinteract tools provided by the TPP. Includes PeptideProphet, InterProphet and ProteinProphet
#

require 'optparse'
require 'ostruct'
require 'pathname'
require 'libxml'
require 'protk/search_tool'

class ProphetTool < SearchTool

  include LibXML


  # Initializes the commandline options
  def initialize(option_support={})
    option_support[:prefix_suffix]=true;
    option_support[:over_write]=true;
    
    super(option_support)

  end
    


  # Obtain the database name from the given input file
  #
  def extract_db(file_name)
    reader = XML::Reader.file(file_name)
    throw "Failed to open xml file #{file_name}" unless reader!=nil

    while(reader.read)
      # For pep.xml files
      #
      if ( reader.name == "search_database" )
        dbnode=reader.expand
        dbvalue=dbnode['local_path']
        reader.close
        return dbvalue
      end

      # For prot.xml files
      #
      if ( reader.name == "protein_summary_header" )
        dbnode=reader.expand
        dbvalue=dbnode['reference_database']
        reader.close
        return dbvalue
      end
      
      
      
    end

  end



  # Obtain the search engine name from the input file
  # The name of the engine is returned in lowercase and should contain no spaces
  # Names of common engines are searched for and extracted in simplified form if possible
  #
  def extract_engine(file_name)
    reader = XML::Reader.file(file_name)
    throw "Failed to open xml file #{file_name}" unless reader!=nil

    while(reader.read)
      if ( reader.name == "search_summary" )
        dbnode=reader.expand
        dbvalue=dbnode['search_engine']
        reader.close
        engine_name=dbvalue.gsub(/ /,"_")
        engine_name=engine_name.gsub(/\(/,"")
        engine_name=engine_name.gsub(/\)/,"")
        engine_name=engine_name.gsub(/\!/,"")        
        return engine_name.downcase
      end
    end
  end

end