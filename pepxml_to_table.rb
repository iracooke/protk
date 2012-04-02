#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Convert a pepXML file to a tab delimited table
#
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

require 'libxml'
require 'constants'
require 'command_runner'
require 'tool'

include LibXML

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new({:explicit_output=>true})
tool.option_parser.banner = "Convert a pepXML file to a tab delimited table.\n\nUsage: pepxml_to_table.rb [options] file1.pep.xml"

tool.option_parser.parse!

# Obtain a global environment object
#genv=Constants.new

input_file=ARGV[0]

output_file="#{input_file}.txt"

output_file = tool.explicit_output if tool.explicit_output!=nil

output_fh=File.new("#{output_file}",'w')

output_fh.write "protein\tpeptide\tassumed_charge\tcalc_neutral_pep_mass\tneutral_mass\tretention_time\tstart_scan\tend_scan\tsearch_engine\tpeptideprophet_prob\tinterprophet_prob\n"

pepxml_parser=XML::Parser.file("#{input_file}")
pepxml_doc=pepxml_parser.parse

spectrum_queries=pepxml_doc.find('//xmlns:spectrum_query','xmlns:http://regis-web.systemsbiology.net/pepXML')

spectrum_queries.each do |query| 

  retention_time=query.attributes['retention_time_sec']
  neutral_mass=query.attributes['precursor_neutral_mass']
  assumed_charge=query.attributes['assumed_charge']

  top_search_hit=query.find('./xmlns:search_result/xmlns:search_hit','xmlns:http://regis-web.systemsbiology.net/pepXML')[0]
  peptide=top_search_hit.attributes['peptide']
  protein=top_search_hit.attributes['protein']
  calc_neutral_pep_mass=top_search_hit.attributes['calc_neutral_pep_mass']
  start_scan=query.attributes['start_scan']
  end_scan=query.attributes['end_scan']

  search_engine=""
  search_score_names=top_search_hit.find('./xmlns:search_score/@name','xmlns:http://regis-web.systemsbiology.net/pepXML').collect {|s| s.to_s}

  if ( search_score_names.length==2 && search_score_names.grep(/^name.*=.*pvalue/))
    search_engine="omssa" 
  elsif ( search_score_names.grep(/^name.*=.*ionscore/))
    search_engine="mascot"
  elsif ( search_score_names.grep(/^name.*=.*hyperscore/) )
    search_engine="x!tandem"
  end

  pp_result=top_search_hit.find('./xmlns:analysis_result/xmlns:peptideprophet_result/@probability','xmlns:http://regis-web.systemsbiology.net/pepXML')
  ip_result=top_search_hit.find('./xmlns:analysis_result/xmlns:interprophet_result/@probability','xmlns:http://regis-web.systemsbiology.net/pepXML')
  
  peptide_prophet_prob=""
  interprophet_prob=""
  peptide_prophet_prob=pp_result[0].value if ( pp_result.length>0 )
  interprophet_prob=ip_result[0].value if ( ip_result.length>0)
  
  output_fh.write "#{protein}\t#{peptide}\t#{assumed_charge}\t#{calc_neutral_pep_mass}\t#{neutral_mass}\t#{retention_time}\t#{start_scan}\t#{end_scan}\t#{search_engine}\t#{peptide_prophet_prob}\t#{interprophet_prob}\n"

end

output_fh.close