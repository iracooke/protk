#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Convert a pepXML file to a tab delimited table
#
#

require 'libxml'
require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'

include LibXML

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output])
tool.option_parser.banner = "Convert a pepXML file to a tab delimited table.\n\nUsage: pepxml_to_table.rb [options] file1.pep.xml"

exit unless tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts tool.option_parser 
    exit
end

# Obtain a global environment object
#genv=Constants.new

input_file=ARGV[0]

output_file="#{input_file}.txt"

output_file = tool.explicit_output if tool.explicit_output!=nil

output_fh=File.new("#{output_file}",'w')

output_fh.write "protein\tpeptide\tassumed_charge\tcalc_neutral_pep_mass\tneutral_mass\tretention_time\tstart_scan\tend_scan\tsearch_engine\tpeptideprophet_prob\tinterprophet_prob\n"

XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

pepxml_parser=XML::Parser.file("#{input_file}")

pepxml_ns_prefix="xmlns:"
pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"
 pepxml_doc=pepxml_parser.parse
if not pepxml_doc.root.namespaces.default
  pepxml_ns_prefix=""
  pepxml_ns=nil
end


spectrum_queries=pepxml_doc.find("//#{pepxml_ns_prefix}spectrum_query", pepxml_ns)

spectrum_queries.each do |query| 

  retention_time=query.attributes['retention_time_sec']
  neutral_mass=query.attributes['precursor_neutral_mass']
  assumed_charge=query.attributes['assumed_charge']

  top_search_hit=query.find("./#{pepxml_ns_prefix}search_result/#{pepxml_ns_prefix}search_hit",pepxml_ns)[0]
  peptide=top_search_hit.attributes['peptide']
  protein=top_search_hit.attributes['protein']
  calc_neutral_pep_mass=top_search_hit.attributes['calc_neutral_pep_mass']
  start_scan=query.attributes['start_scan']
  end_scan=query.attributes['end_scan']

  search_engine=""
  search_score_names=top_search_hit.find("./#{pepxml_ns_prefix}search_score/@name",pepxml_ns).collect {|s| s.to_s}

  search_engine=query.parent.attributes['search_engine']

  # if ( search_score_names.length==2 && search_score_names.grep(/^name.*=.*pvalue/))
  #   search_engine="omssa" 
  # elsif ( search_score_names.grep(/^name.*=.*ionscore/))
  #   search_engine="mascot"
  # elsif ( search_score_names.grep(/^name.*=.*hyperscore/) )
  #   search_engine="x!tandem"
  # end

  
  pp_result=top_search_hit.find("./#{pepxml_ns_prefix}analysis_result/#{pepxml_ns_prefix}peptideprophet_result/@probability",pepxml_ns)
  ip_result=top_search_hit.find("./#{pepxml_ns_prefix}analysis_result/#{pepxml_ns_prefix}interprophet_result/@probability",pepxml_ns)

  peptide_prophet_prob=""
  interprophet_prob=""
  peptide_prophet_prob=pp_result[0].value if ( pp_result.length>0 )
  interprophet_prob=ip_result[0].value if ( ip_result.length>0)
  
  output_fh.write "#{protein}\t#{peptide}\t#{assumed_charge}\t#{calc_neutral_pep_mass}\t#{neutral_mass}\t#{retention_time}\t#{start_scan}\t#{end_scan}\t#{search_engine}\t#{peptide_prophet_prob}\t#{interprophet_prob}\n"

end

output_fh.close