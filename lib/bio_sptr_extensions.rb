# Add methods to the Bio::SPTR class to retrieve objects using the keys defined in proteinannotator.rb
#
# newColumnKeys=['recname','cd','altnames','accessions','location','function','ipi','intact','pride','ensembl','refsMASS SPEC','refsNUCLEOTIDE SEQUENCE','refsX-RAY CRYSTALLOGRAPHY','refs3D-STRUCTURE MODELLING','refsPROTEIN SEQUENCE','refsGLYCOSYLATION','glycosites']
#
#

## We start the columns off with the header name
#newColumns={'recname'=>["Primary Name"],'cd'=>["CD Antigen Name"],'altnames'=>["Alternate Names"], 
#  'accessions' =>["Swissprot Accessions"],
#  'location' => ["Subcellular Location"],
#  'function' => ["Known Function"],
#  'ipi' => ["IPI"],
#  'intact' => ["Interactions"],
#  'pride' => ['Pride'],
#  'ensembl'=> ['Ensembl'],
#  'refsMASS SPEC'=>["MS Refs"], 
#  'refsGLYCOSYLATION'=>["Glyco Refs"], 
#  'refsNUCLEOTIDE SEQUENCE'=>["Nucleotide Refs"], 
#  'refsX-RAY CRYSTALLOGRAPHY'=>["Crystallography Refs"],
#  'refs3D-STRUCTURE MODELLING'=>["3D-Modelling Refs"],
#  'refsPROTEIN SEQUENCE'=>["Protein sequence Refs"],
#  'glycosites'=>["Glycosylation Sites"]    
#}
require 'rubygems'
require 'bio'

class Bio::SPTR < Bio::EMBLDB

  #
  # Functions corresponding to retrieving data for specific keys
  #  

  # The recommended name for the Protein
  #
  def recname
    pname_field=self.de
    entries=pname_field.split(";")
    entries.each do |entry|
      m=entry.match(/\s*(.*?):\s*(.*?)=(.*)/)
      if ( m!=nil)
        if ( m[1]=="RecName")
          return m[3]
        end
      end
    end   
    return ""
  end
  
  # The CD Antigen name
  #
  def cd
    pname_field=self.de
    entries=pname_field.split(";")
    entries.each do |entry|
      m=entry.match(/\s*(.*?):\s*(.*?)=(.*)/)
      if ( m!=nil)
        if ( (m[1]=="AltName") && (m[2]=="CD_antigen") )
          return m[3]
        end
      end
    end
    
    return ""
  end

  # All alternate names
  #
  def altnames
    altnames=""
    
    pname_field=self.de
    entries=pname_field.split(";")
    entries.each do |entry|
      m=entry.match(/\s*(.*?):\s*(.*?)=(.*)/)
      if ( m!=nil)
        if ( (m[1]=="AltName") && (m[2]!="CD_antigen") )
          altnames << "#{m[3]}; "
          
        end
      end
    end
    
    if ( altnames!="") # Get ride of extraneous "; "
      altnames.chop!.chop!
    end
    
    return altnames
  end
  
  # SwissProt Accessions
  #
  def accessions 
    return ""
  end

  # Subcellular Location
  #
  def location
    return self.cc["SUBCELLULAR LOCATION"].to_s
  end

  # Function
  #
  def function
    return self.cc["FUNCTION"].to_s    
  end

  # Similarity
  #
  def similarity
    return self.cc["SIMILARITY"].to_s    
  end
  
  # Tissue Specificity
  #
  def tissues
    return self.cc["TISSUE SPECIFICITY"].to_s
  end
  
  # Disease
  #
  def disease
    return self.cc["DISEASE"].to_s
  end

  # Subunit
  def subunit
    return self.cc["SUBUNIT"].to_s
  end

  # Domain
  def domain
    return self.cc["DOMAIN"].to_s
  end
  
  # 
  # Getting dr entry
  # 

  # Helper Function to create links
  #
  def safely_get_drentry_for_key(key)
    if ( self.dr[key]==nil)
      return ""
    end

    return dr[key][0][0]
  end

  # IPI Accession number
  # 
  def ipi
    return self.safely_get_drentry_for_key("IPI")
  end
  
  # Intact accession number
  #
  def intact
    return self.safely_get_drentry_for_key("PRIDE")    
  end

  # Pride accession number
  #
  def pride
    return self.safely_get_drentry_for_key("PRIDE")
  end
  
  # Ensembl accession number
  #
  def ensembl
    return self.safely_get_drentry_for_key("Ensembl")
  end
  
  # NextBIO accession number
  #
  def nextbio
    return self.safely_get_drentry_for_key("NextBio")
  end
  
  
  # Number of transmembrane regions
  #
  def num_transmem
    begin
      if ( self.ft["TRANSMEM"]==nil)
        return 0.to_s
      else
        return self.ft["TRANSMEM"].length.to_s
      end
    rescue
      p "Warning: Unable to parse feature table for entry #{self.accession}"
    end
  end


  # Number of signal peptide features
  #
  def signalp
    begin
      if ( self.ft["SIGNAL"]==nil)
        return 0.to_s
      else
        return self.ft["SIGNAL"].length.to_s
      end
    rescue
      p "Warning: Unable to parse feature table for entry #{self.accession}"      
    end
  end
  
end
