
class MascotUtil 


  # Reads a mascot dat file and returns the basename of the original search file
  #
  def self.input_basename(dat_file)

    dat=File.new(dat_file)
    filename=""
    dat.each_line do |line|
      if ( line=~ /^File/i)
        p line
        m=line.match(/^File=.*?[\/\\]?(.*)\.[md][ga][tf]/i)
        if ( m!=nil )
          filename=m[1]
        end
      end
    end

    return filename

  end
  
  def self.remove_charge_from_title_string(tstring)

    if ( tstring=~/(.*)\..*?\..*?\.$/)
      return tstring.chop
    end
    
    if ( tstring=~/(.*)\..*?\..*?\.\d$/)
      return tstring.chop!.chop
    end

    if ( tstring=~/(.*)\..*?\..*?$/)
      return tstring
    end    
    
    throw "Unrecognised title string format #{tstring}"
    
  end
  
  # Create a hashtable which maps spectrum references to retention times for an mgf file
  #
  def self.index_mgf_times(mgf_file)
   rt_table=Hash.new()
   mgf=File.new(mgf_file)

   mgf.each(sep="END IONS") do |line|

     spec=line.match(/TITLE=(.*?)$/)

     rt=line.match(/RTINSECONDS=(.*?)$/)

     if ( spec!=nil && rt!=nil)
       # Remove charge from the end of the title
       # spec_id= remove_charge_from_title_string(spec[1])
       spec_id= spec[1]

    #   $stdout.write "#{spec_id} \r"

       
       rt_table[spec_id]=rt[1]
     end

   end
#    $stdout.write "\n"

   return rt_table
    
  end

end