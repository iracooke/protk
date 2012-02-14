#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the Mascot search engine
#

#!/bin/sh
# -------+---------+---------+-------- + --------+---------+---------+---------+
#     /  This section is a safe way to find the interpretter for ruby,  \
#    |   without caring about the user's setting of PATH.  This reduces  |
#    |   the problems from ruby being installed in different places on   |
#    |   various operating systems.  A much better solution would be to  |
#    |   use  `/usr/bin/env -S-P' , but right now `-S-P' is available    |
#     \  only on FreeBSD 5, 6 & 7.                        Garance/2005  /
# To specify a ruby interpreter set PROTK_RUBY_PATH in your environment. 
# Otherwise standard paths will be searched for ruby
#
if [ -z "$PROTK_RUBY_PATH" ] ; then
  
  for fname in /usr/local/bin /opt/csw/bin /opt/local/bin /usr/bin ; do
    if [ -x "$fname/ruby" ] ; then PROTK_RUBY_PATH="$fname/ruby" ; break; fi
  done
  
  if [ -z "$PROTK_RUBY_PATH" ] ; then
    echo "Unable to find a 'ruby' interpretter!"   >&2
    exit 1
  fi
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#


$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")

require 'constants'
require 'command_runner'
require 'search_tool'
require 'rest_client'

# Environment with global constants
#
genv=Constants.new

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new({:msms_search=>true,:background=>false,:database=>true,:explicit_output=>true,:over_write=>true,:msms_search_detailed_options=>true})
search_tool.jobid_prefix="o"
search_tool.option_parser.banner = "Run a Mascot msms search on a set of mgf input files.\n\nUsage: mascot_search.rb [options] file1.mgf file2.mgf ..."
search_tool.options.output_suffix="_mascot"

search_tool.options.mascot_server="#{genv.default_mascot_server}/mascot/cgi"
search_tool.option_parser.on( '-S', '--server url', 'The url to the cgi directory of the mascot server' ) do |url| 
  search_tool.options.mascot_server=url
end

search_tool.options.http_proxy="http://squid.latrobe.edu.au:8080"
search_tool.option_parser.on( '-P', '--http-proxy url', 'The url to a proxy server' ) do |url| 
  search_tool.options.http_proxy=url
end

search_tool.option_parser.parse!





# Set search engine specific parameters on the SearchTool object
#
fragment_tol = search_tool.fragment_tol
precursor_tol = search_tool.precursor_tol



mascot_cgi=search_tool.mascot_server

## For testing this is all hard coded
# Add command-line options to allow all these to be specified
#
RestClient.proxy=search_tool.http_proxy

genv.log("Var mods #{search_tool.var_mods} and fixed #{search_tool.fix_mods}",:info)

var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }.join(",")
fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }.join(",")

# None is given by a an empty galaxy multi-select list. 
#
var_mods=""  if var_mods=="None"
fix_mods="" if fix_mods=="None"

postdict={}

# CHARGE
#
postdict[:CHARGE]=search_tool.allowed_charges

# CLE
#
postdict[:CLE]=search_tool.enzyme

# PFA
#
postdict[:PFA]=search_tool.missed_cleavages

# COM (Search title)
# 
postdict[:COM]="Protk"

# DB (Database)
#
postdict[:DB]=search_tool.database

# INSTRUMENT
#
postdict[:INSTRUMENT]=search_tool.instrument

# IT_MODS (Variable Modifications)
#
postdict[:IT_MODS]=var_mods

# ITOL (Fragment ion tolerance)
#
postdict[:ITOL]=search_tool.fragment_tol

# ITOLU (Fragment ion tolerance units)
#
postdict[:ITOLU]=search_tool.fragment_tolu

# MASS (Monoisotopic and Average)
#
postdict[:MASS]=search_tool.precursor_search_type

# MODS (Fixed modifications)
#
postdict[:MODS]=fix_mods

# REPORT (What to include in the search report. For command-line searches this is pretty much irrelevant)
#
postdict[:REPORT]="AUTO"

# TAXONOMY (Blank because we don't allow taxonomy)
#
postdict[:TAXONOMY]=""

# TOL (Precursor ion tolerance (Unit dependent))
#
postdict[:TOL]=search_tool.precursor_tol

# TOLU (Tolerance Units)
#
postdict[:TOLU]=search_tool.precursor_tolu

# Email
#
postdict[:USEREMAIL]=search_tool.email

# Username
#
postdict[:USERNAME]=search_tool.username


# FILE
#
postdict[:FILE]=File.new(ARGV[0])

postdict[:FORMVER]='1.01'
postdict[:INTERMEDIATE]=''

genv.log("Sending #{postdict}",:info)

search_response=RestClient.post "#{mascot_cgi}/nph-mascot.exe?1",  postdict

genv.log("Mascot search response was #{search_response}",:info)

# Look for an error if there is one
error_result= /Sorry, your search could not be performed(.*)/.match(search_response)
if ( error_result != nil )
  p error_result[0]
  genv.log("Mascot search failed with response #{search_response}",:warn)
  throw "Mascot search failed with response #{search_response}"
else

  # Search for the location of the mascot data file in the response
  results=/master_results_?2?\.pl\?file=\.*\/data\/(.*)\/(.+\.dat)/.match(search_response)
  results_date=results[1]
  results_file=results[2]


  get_url= "#{mascot_cgi}/../x-cgi/ms-status.exe?Autorefresh=false&Show=RESULTFILE&DateDir=#{results_date}&ResJob=#{results_file}" 

  if ( search_tool.explicit_output!=nil)
    output_path=search_tool.explicit_output
  else
    output_path="#{results_file}"
  end

  require 'open-uri'
  open("#{output_path}", 'wb') do |file|
    file << open("#{get_url}").read
  end
end

