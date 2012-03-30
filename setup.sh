#!/bin/bash

# Check for rvm (required to install ruby and its dependencies)
#
result=`which rvm`
if [ $? -ne 0 ] 
    then
    # No rvm ask the user if they want it
    echo "rvm (Ruby enVironment Manager) is not installed. This script can automatically install rvm for you. \nIf you choose to install, all files will be installed under ~/.rvm/ and your ~/.profile or ~/.bash_profile will be modified. Would you like to install rvm now?"
    select yn in "Yes" "No"; do
        case $yn in
            Yes ) bash -s stable < <(curl -sk https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer );source "$HOME/.rvm/scripts/rvm"; break;;
            No ) exit;;
        esac
    done
else
    echo "Found rvm in $result"
#    source "$HOME/.rvm/scripts/rvm"
fi

# Check for git (required by rvm)
#
result=`which git`
if [ $? -ne 0 ] 
    then echo "git is not installed. Protk needs git to manage its internal packages\nYou can download and install git from here http://git-scm.com/";
    exit;
else
  echo "Found git in $result"  
fi

# Try to get rvm to install our required ruby
#
result=`rvm install ruby-1.8.7`
if [ $? -ne 0 ] 
    then echo "Failed to install protk's preferred version of ruby. Will try using the system default ruby";
    result=`ruby --version`
    if [ $? -ne 0 ]
      then echo "No system ruby has been installed"
      exit;  
    fi
    rvm use system
else
    result=`rvm use ruby-1.8.7`
    echo "Using $result"  
fi

# Check for a config file
#
if [ ! -f "config.yml" ]
    then  `cp config.yml.sample config.yml`  
fi

# Now that we have rvm installed the remaining installation is done with rake
rvm ruby-1.8.7 do rake default $@

if [ $? -ne 0 ]
    then echo "Installation failed"
else
  echo "Installation was successful.\n\nDatabases still need to be installed\nUse the manage_db.rb tool to install databases"  
fi