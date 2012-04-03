
temp_file=`mktemp protkXXX`
export temp_file

bash << %%%
export PATH=/Users/iracooke/Sources/protk/:${PATH}

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

#cat $temp_file
. $temp_file

rm $temp_file