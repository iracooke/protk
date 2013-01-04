temp_file=`mktemp /tmp/protkXXX`
export temp_file

bash << %%%

[[ -s "$HOME/.rvm/scripts/rvm" ]] && source "$HOME/.rvm/scripts/rvm"


rvm 1.9.3

export | grep 'declare -x' | sed 's/declare -x/export/g' > $temp_file

%%%

. $temp_file

rm $temp_file