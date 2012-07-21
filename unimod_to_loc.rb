#
# This file is part of MSLIMS
# Created by Ira Cooke 12/4/2010
#
# Reads a unimod xml file (eg from a Mascot installation) and produces a loc file with names of allowable chemical modifications
#
#!/bin/sh
. `dirname \`readlink -f $0\``/protk_run.sh
#! ruby
#

require 'libxml'

include LibXML

unimod_file=ARGV[0]

unimod_file=XML::Parser.file(unimod_file)
unimod_doc=unimod_file.parse


all_mods=[]

umd = unimod_doc.find('//umod:unimod/umod:modifications/umod:mod')

umd.each { |mod| 
  
  # Special Cases
  #
  title=mod.attributes['title']
  if ( title=="Oxidation" || title=="Phospho" || title=="Sulfo")
    if ( title=="Oxidation")
      all_mods.push("Oxidation (HW)")
      all_mods.push("Oxidation (M)")
    end
    
    if ( title=="Phospho")
      all_mods.push("Phospho (ST)")
      all_mods.push("Phospho (Y)")      
    end
    
    if ( title=="Sulfo")
      all_mods.push("Sulfo (S)")
      all_mods.push("Sulfo (T)")      
      all_mods.push("Sulfo (Y)")      
    end
    
  else
  
    # Deal with the anywhere sites which can be concatenated
    #
    if ( mod.attributes['title'] !~ /^iTRAQ/ && mod.attributes['title'] !~ /^mTRAQ/ )
      anywhere_sites = mod.find('./umod:specificity[@hidden="0" and @position="Anywhere"]')
      if ( anywhere_sites.length>0 )

        sites=[]

        anywhere_sites.each { |s| 
          sites.push("#{s.attributes['site']}")
        }
        sites.sort!
        specificity="("
        sites.each { |s| specificity<<s }
        specificity<<")"

        all_mods.push("#{mod.attributes['title']} #{specificity}")
         
      end    
    
    else
      anywhere_sites = mod.find('./umod:specificity[@hidden="0" and @position="Anywhere"]')
      anywhere_sites.each { |s| 
        all_mods.push("#{mod.attributes['title']} (#{s.attributes['site']})")    
      }
    end

    specifics=mod.find('./umod:specificity[@hidden="0" and @position!="Anywhere"]')
    if ( specifics.length > 0 )
      specifics.each { |specific_mod|

        specificity=specific_mod.attributes['site']
        if ( specific_mod.attributes['position'] =~ /^Protein/)
          specificity=specific_mod.attributes['position']
        end

        if ( (specific_mod.attributes['position'] =~ /Any N-term/) && (specific_mod.attributes['site'] =~ /^[CQEM]$/) )
          specificity="N-term #{specific_mod.attributes['site']}"
        end

        if ( (specific_mod.attributes['position'] =~ /Any C-term/) && (specific_mod.attributes['site'] =~ /^[M]$/) )
          specificity="C-term #{specific_mod.attributes['site']}"
        end

        all_mods.push("#{mod.attributes['title']} (#{specificity})")
        
      }
      
    end
    
  end
  
}


all_mods=all_mods.sort {|a,b| a.downcase <=> b.downcase}

loc_output=File.new("mascot_mods.loc",'w')

loc_output << "#This file lists the names of chemical modifications acceptable for proteomics search engines\n"
loc_output << "#\n"
loc_output << "#So, unimod_names.loc could look something like this:\n"
loc_output << "#\n"

all_mods.each { |am| 
  key = am.downcase.gsub(" ","").gsub("\(","\_").gsub("\)","\_").gsub("\:","\_").gsub("\-\>","\_")
  loc_output << "#{am}\t#{key}\t#{am}\t#{key}\n"
}

loc_output.close


