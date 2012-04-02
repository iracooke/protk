#!/bin/bash

# Check for rvm (required to install ruby and its dependencies)
#
result=`which rvm`
if [ $? -ne 0 ] 
    then
    # No rvm ask the user if they want it
    echo "rvm (Ruby enVironment Manager) is not installed. This script can automatically install rvm for you. If you choose to install, all files will be installed under ~/.rvm/ and your ~/.profile or ~/.bash_profile will be modified. After the install this script will exit and you should run \'rvm notes\' and \'rvm requirements\' to check for additional config steps that might be required for rvm to work properly. Would you like to install rvm now? (Type 1 for Yes, 2 for No)"
    options=('Yes' 'No')
    select opt in "${options[@]}"; do
        echo $opt
        case $opt in
            'Yes' ) bash -s stable < <(curl -sk https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer );source "$HOME/.rvm/scripts/rvm"; echo "Check \'rvm requirements\' and run setup again"; exit;
            break;;
            'No' ) 
            exit
            break;;
            *) echo invalid option;;
        esac
    done
    
else

    echo "Found rvm in $result"

    # Check for git (required by rvm)
    #
    resultg=`which git`
    if [ $? -ne 0 ] 
        then echo "git is not installed. Protk needs git to manage its internal packages. You can download and install git from here http://git-scm.com/";
        exit;
    else
      echo "Found git in $resultg"  
    fi

    
    # Construct an rvm sourcing line
    rvm_script=${result%/bin/rvm}/scripts/rvm
    
    sourcing_command="[[ -s $rvm_script ]] && source $rvm_script"
    cwd=`pwd`
    
    if [ -f ./env.sh ]
        then
        echo "Warning: Skipping creation of env.sh ... file exists. Delete env.sh to regenerate it using this script";

    else
        echo $cwd;
        echo "export PATH=$cwd/:\${PATH}; $sourcing_command; rvm use 1.8.7" > env.sh;
    fi
      
    source ./env.sh
    if [ $? -ne 0 ]
        then 
        echo "Error: Unable to setup protk environment. You may need to manually modify the file 'env.sh' and then rerun setup.sh"; exit;
    else
      echo "Created shell setup script for protk in env.sh . Galaxy wrappers will automatically source this file. For commandline use you may wish to add the following to your login shell."
      echo " "
      echo "export PATH=$cwd/:\${PATH};"
      echo "$sourcing_command" 
      echo "rvm use 1.8.7";
      echo " "
      
    fi

fi



result=`rvm list | grep ruby-1.8.7`
if [ $? -ne 0 ]
    then
    # Try to get rvm to install our required ruby
    #
    result=`rvm install ruby-1.8.7`
    if [ $? -ne 0 ] 
        then echo "Failed to install protk's preferred version of ruby";
        exit;
    fi
fi

# Make sure we're using the proper ruby
#
result=`rvm use 1.8.7`
if [ $? -ne 0 ]
    then echo "Failed to switch to rvm's ruby 1.8.7";
    exit;
fi


# Check for a config file
#
if [ ! -f "config.yml" ]
    then  `cp config.yml.sample config.yml`  
fi

cd `pwd`

# Now that we have rvm installed the remaining installation is done with rake
rvm 1.8.7 do rake default $@

if [ $? -ne 0 ]
    then echo "Installation failed"
else
  echo "Installation was successful."
  echo "Databases still need to be installed. "
  echo "The manage_db tool can be used to install databases. For further information;"
  echo "   ./manage_db.rb -h"
  echo "   ./manage_db.rb add -h"
fi