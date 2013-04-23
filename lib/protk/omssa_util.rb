require 'libxml'
require 'protk/mascot_util'
include LibXML


class OMSSAUtil 



  # Reads a pepxml file and modifies it to include retention time info.
  # The modified xml doc is returned but not yet saved
  #
  def self.add_retention_times(mgf_file,pepxml_file,over_write=false,save=false)
    parser=XML::Parser.file(pepxml_file)
    pepxml_doc=parser.parse
    rt_table=MascotUtil.index_mgf_times(mgf_file)
    
 #   p "Retention time table #{rt_table}"
    
#    queries=pepxml_doc.find('//x:spectrum_query','x:http://regis-web.systemsbiology.net/pepXML')
    queries=pepxml_doc.find('//spectrum_query')    
    i=0
    queries.each do |query|

      atts=query.attributes
      spect=atts["spectrum"]
      spect.chop!.chop! # Remove charge ... presume it isn't greater than 9!
      
      throw "No spectrum found for spectrum_query #{query}" unless ( spect!=nil)
      throw "No retention time found for spectrum #{spect}. Most likely MALDI data was converted without specifying MALDI option." unless (rt_table[spect]!=nil)
      
      if ( queries[i].attributes["retention_time_sec"]!=nil )
        throw "A retention time value is already present" unless over_write
      end


      if ( queries[i].attributes["retention_time_sec"]==nil || over_write)
        queries[i].attributes["retention_time_sec"]=rt_table[spect]       
        p queries[i].attributes["retention_time_sec"] 
      end
      
      
      i=i+1
    end

    if ( save)
      pepxml_doc.save(pepxml_file)
    end

    return pepxml_doc
  end
  
  
  


end