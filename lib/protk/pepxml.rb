require 'rubygems'
require 'libxml'

include LibXML

# require 'rexml/document'
# require 'rexml/xpath'

class PepXML

  attr_accessor :file_name

  def initialize(file_name)
    @file_name=file_name

    XML::Error.set_handler(&XML::Error::QUIET_HANDLER)
    pepxml_parser=XML::Parser.file("#{file_name}")

    @pepxml_ns_prefix="xmlns:"
    @pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"
    @pepxml_doc=pepxml_parser.parse
    if not @pepxml_doc.root.namespaces.default
      @pepxml_ns_prefix=""
      @pepxml_ns=nil
    end
  end


  
  # Obtain the database name from the given input file
  #
  def extract_db()
    reader = XML::Reader.file(self.file_name)
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
  def extract_engine()
    reader = XML::Reader.file(self.file_name)
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


  def extract_enzyme()
    reader = XML::Reader.file(self.file_name)
    throw "Failed to open xml file #{file_name}" unless reader!=nil

    while(reader.read)
      if ( reader.name == "sample_enzyme" )
        dbnode=reader.expand
        dbvalue=dbnode['name']
        reader.close        
        return dbvalue.downcase
      end
    end
  end



  def type_from_base_name(basename)
    # A common error is for tools to include the extension in the base_name attribute.
    # We exploit this to guess the type
    ext_guess=""
    case basename
    when /.mgf$/
      ext_guess="mgf"
    when /.mzML$/
      ext_guess="mzML"
    when /.mzXML$/
      ext_guess="mzXML"
    else
      ext_guess=""
    end
    ext_guess
  end

  def type_from_summary_attributes(atts)
    if is_valid_type(atts["raw_data_type"])
      return  atts["raw_data_type"]
    end

    if is_valid_type(atts["raw_data"])
      return atts["raw_data"]
    end
    return ""
  end

  def is_valid_type(type)
    case type
    when /^mgf$/i
      return true
    when /^mzML$/i
      return true
    when /^mzXML$/i
      return true
    else
      return false
    end
  end


  # TODO: Make this faster and more memory efficient by using XML::Reader as in the functions above
  #
  def find_runs()


    run_summaries = @pepxml_doc.find("//#{@pepxml_ns_prefix}msms_run_summary", @pepxml_ns)

    runs = {}
    run_summaries.each do |summary|
      base_name = summary.attributes["base_name"]
      if not runs.has_key?(base_name)
        bn = summary.attributes["base_name"]

        runs[base_name] = {:base_name => summary.attributes["base_name"]}

        if is_valid_type(type_from_summary_attributes(summary.attributes))
          runs[base_name][:type] = type_from_summary_attributes(summary.attributes)
        elsif is_valid_type(type_from_base_name(bn))
          runs[base_name][:type] = type_from_base_name(bn)
        else
          runs[base_name][:type] = "mzML" # Same guess as peptide prophet makes
        end

      end
    end
    runs
  end


  
end