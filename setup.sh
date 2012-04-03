#!/bin/bash

super() {
	if [ `id -u` -eq 0 ]; then
		$@
	elif [ "`which sudo 2>/dev/null`" ]; then
		sudo -E $@
	elif [ "`which su 2>/dev/null`" ]; then
		su -c "$@" `whoami`
	elif [ "`which pfexec 2>/dev/null`" ]; then
		pfexec $@
	else
		$@
	fi
	return $?
}


get() {
	if [ "`which apt-get 2>/dev/null`" ]; then
		echo "apt-get install --yes $1"
	elif [ "`which yum 2>/dev/null`" ]; then
		echo "yum -y install $1"
	elif [ "`which zypper 2>/dev/null`" ]; then
		echo "zypper -n install $1"
	fi
}

ask() {
    echo -n "$1 [Yes/No]: "
    while true; do
        read ans
        case $ans in
            [Yy][Ee][Ss]|[Yy]|1) return 1; break;;
            [Nn][Oo]|[Nn]|2) return 0; break;;
            *) echo "invalid option";;
        esac
    done
}

echo -n "Checking for curl: "
if [ `which curl 2>/dev/null` ]; then
    echo `which curl`
else
    echo "not found"
    install=`get git`
    if [ "$install" ]; then
        echo "The following commands need to be run as the root user to install curl"
        echo "$install"
        ask "Would you like to run these commands?"
        if [ $? -eq 1 ]; then 
            super $install
        else
            exit
        fi
    else
        echo "Could not find a suitable package"
    fi
fi

# Check for rvm (required to install ruby and its dependencies)
#

echo -n "Checking for rvm (Ruby enVironment Manager): "
if [ `which rvm 2>/dev/null` ]; then
    echo `which rvm`
else
    echo "not found"
    if (( UID == 0 )); then
	    echo "rvm will be installed under /usr/local/rvm and a link will be made in $HOME/.rvm/"
    else
	    echo "rvm will be installed under ~/.rvm/ and your ~/.profile or ~/.bash_profile will be modified"
	fi
    ask "Would you like to install rvm now?"
    if [ $? -eq 1 ]; then
        bash -s stable --path "$HOME/.rvm" << %%%
`curl -sk https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer`
%%%
		if [ `id -u` -eq 0 ]; then
		    ln -s "/usr/local/rvm" "$HOME/.rvm"
		fi
        source "$HOME/.rvm/scripts/rvm"
    else
        exit
    fi
fi

echo -n "Checking rvm configuration: "
install=`rvm requirements | grep -A99 "Additional Dependencies:" | sed "1 d" | grep "\bruby: " | sed 's/^\s*ruby:\s*//'` | sed 's/\s*#.*$//'`
if [ "$install" ]; then
    echo "missing packages"
    echo "The following commands need to be run as the root user to correct the installation"
    echo "Some or all of these packages may already be installed"
    echo "$install"
    ask "Would you like to run these commands?"
    if [ $? -eq 1 ]; then 
        super $install
    #else
    #    exit
    fi
else
    echo "correct"
fi

echo -n "Checking for git (required by rvm): "
if [ "`which git 2>/dev/null`" ]; then
    echo `which git`
else
    echo "not found"
    install=`get git`
    if [ "$install" ]; then
        echo "The following commands need to be run as the root user to install git"
        echo "$install"
        ask "Would you like to run these commands?"
        if [ $? -eq 1 ]; then 
            super $install
        else
            exit
        fi
    else
        echo "Could not find a suitable package"
    fi
fi

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then

    # First try to load from a user install
    source "$HOME/.rvm/scripts/rvm";

elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then

    # Then try to load from a root install
    source "/usr/local/rvm/scripts/rvm"

else

    printf "ERROR: An RVM installation was not found.\n"

fi

echo -n "Setting up the galaxy environment: "
if [ -f ./env.sh ]; then
    echo "skipping (file exists)"
    echo "Delete env.sh to regenerate it using this script";
else
    echo `pwd`
    cat >env.sh <<EOF
temp_file=`mktemp protkXXX`
export temp_file

bash << %%%
export PATH=`pwd`:\${PATH}

# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then

  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm";

elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then

  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"

else

  printf "ERROR: An RVM installation was not found.\n"

fi

rvm 1.8.7

export | grep 'declare -x' | sed 's/declare -x/export/g' >$temp_file

%%%

. $temp_file

rm $temp_file
EOF
fi
if [ $? -ne 0 ]; then 
    echo "write error"
    echo "You may need to manually modify the file 'env.sh' and then rerun setup.sh"
    exit
else
    echo "done"
    echo "For commandline use you may wish to add the following to your login shell."
    echo " "
    echo ". `pwd`/env.sh"
fi

rb_version="1.8.7"
echo -n "Checking for ruby $rb_version: "
result=`rvm list | grep $rb_version`
if [ $? -ne 0 ]; then
    echo "installing/compiling"
    # Try to get rvm to install our required ruby
    #
    result=`rvm install $rb_version`
    if [ $? -ne 0 ]; then
        echo "failed"
        exit
    else
        echo "done"
    fi
else
    echo "found"
fi

# Make sure we're using the proper ruby
#
echo -n "Changing to ruby $rb_version: "
result=`rvm use 1.8.7`
if [ $? -ne 0 ]; then
    echo "failed"
    exit
else
    echo "done"
fi


# Check for a config file
#
if [ ! -f "config.yml" ]
    then  `cp config.yml.sample config.yml`  
fi

# Now that we have rvm installed the remaining installation is done with rake
echo "Passing setup to rake"
rvm install rake
rvm 1.8.7 do rake default $@

if [ $? -ne 0 ]; then
    echo "Installation failed"
else
    echo "Installation was successful."
    echo "Databases still need to be installed. "
    echo "The manage_db tool can be used to install databases. For further information;"
    echo "   ./manage_db.rb -h"
    echo "   ./manage_db.rb add -h"
fi
