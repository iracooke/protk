#!/bin/sh                                                                       
if [ -z "$PROTK_RUBY_PATH" ] ; then
    PROTK_RUBY_PATH=`which ruby`
fi

DIRECTORY="$( cd "$( dirname "$0" )" && pwd )"
export RUBYLIB=$RUBYLIB:$DIRECTORY/lib

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1