#
# This file is part of MSLIMS
# Created by Ira Cooke 12/4/2010
#
# Generates files required by the omssa galaxy wrapper
#
#!/bin/sh
# -------+---------+---------+-------- + --------+---------+---------+---------+
#     /  This section is a safe way to find the interpretter for ruby,  \
#    |   without caring about the user's setting of PATH.  This reduces  |
#    |   the problems from ruby being installed in different places on   |
#    |   various operating systems.  A much better solution would be to  |
#    |   use  `/usr/bin/env -S-P' , but right now `-S-P' is available    |
#     \  only on FreeBSD 5, 6 & 7.                        Garance/2005  /
if [ -z "$PROTK_RUBY_PATH" ] ; then
  
  for fname in /usr/local/bin /opt/csw/bin /opt/local/bin /usr/bin ; do
    if [ -x "$fname/ruby" ] ; then PROTK_RUBY_PATH="$fname/ruby" ; break; fi
  done
  
  if [ -z "$PROTK_RUBY_PATH" ] ; then
    PROTK_RUBY_PATH=`which ruby`
#    echo "Unable to find a 'ruby' interpretter!"   >&2
#    exit 1
  fi
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

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


