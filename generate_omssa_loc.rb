#
# This file is part of MSLIMS
# Created by Ira Cooke 12/4/2010
#
# Generates files required by the omssa galaxy wrapper
#
#!/bin/sh
. `dirname \`readlink -f $0\``/protk_run.sh
#! ruby
#

require 'constants'
# Environment with global constants
#
genv=Constants.new

# Set search engine specific parameters on the SearchTool object
#
omssa_bin="#{genv.omssa_bin}/omssacl"
# Get ommssa to print out a list of its acceptable modifications
acceptable_mods=%x[#{omssa_bin} -ml].split(/\n/).collect do |mod|  

mod_vals=mod.split(":") 
[mod_vals[0].lstrip.rstrip,mod_vals[1].lstrip.rstrip]

end

# Drop the header
#
acceptable_mods.shift

loc_output=File.new("omssa_mods.loc",'w')

loc_output << "#This file lists the names of chemical modifications accepted by OMMSA\n"
loc_output << "#\n"
loc_output << "#\n"

acceptable_mods.each { |am| 
  key = am[1].downcase.gsub(" ","").gsub("\(","\_").gsub("\)","\_").gsub("\:","\_").gsub("\-\>","\_")
  loc_output << "#{am[1]}\t#{key}_\t#{am[0]}\t#{key}_\n"
}

loc_output.close


