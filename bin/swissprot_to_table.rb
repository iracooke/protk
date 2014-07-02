#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Convert a pepXML file to a tab delimited table
#
#
require 'protk/swissprot_database'

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output,:database])
tool.option_parser.banner = "Query a swissprot flat file and output to tab delimited table.\n\nUsage: swissprot_to_table.rb [options] -d flatfile.dat queries.txt"

exit unless tool.check_options(true,[:database])

input_file=ARGV[0]

if tool.explicit_output
  output_fh=File.new("#{tool.explicit_output}",'w')  
else
  output_fh=$stdout
end

swissprotdb=SwissprotDatabase.new()
#     @genv.log("Retrieving data for #{ids.length} entries from Swissprot database ",:info)
#     accs=[]
#     plasmodbids=[]
#     found_plasmodb_ids=false
    
#     $stdout.putc "\n"
#     ids.each { |uniprot_id| 

#       $stdout.putc "."
#       $stdout.flush

#       sptr_entry=swissprotdb.get_entry_for_name(uniprot_id)

# output_fh.write "protein\tpeptide\tassumed_charge\tcalc_neutral_pep_mass\tneutral_mass\tretention_time\tstart_scan\tend_scan\tsearch_engine\traw_score\tpeptideprophet_prob\tinterprophet_prob\n"

# XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

# pepxml_parser=XML::Parser.file("#{input_file}")

# pepxml_ns_prefix="xmlns:"
# pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"
#  pepxml_doc=pepxml_parser.parse
# if not pepxml_doc.root.namespaces.default
#   pepxml_ns_prefix=""
#   pepxml_ns=nil
# end


# spectrum_queries=pepxml_doc.find("//#{pepxml_ns_prefix}spectrum_query", pepxml_ns)

# spectrum_queries.each do |query| 

#   retention_time=query.attributes['retention_time_sec']
#   neutral_mass=query.attributes['precursor_neutral_mass']
#   assumed_charge=query.attributes['assumed_charge']

#   top_search_hit=query.find("./#{pepxml_ns_prefix}search_result/#{pepxml_ns_prefix}search_hit",pepxml_ns)[0]
#   peptide=top_search_hit.attributes['peptide']
#   protein=top_search_hit.attributes['protein']
#   calc_neutral_pep_mass=top_search_hit.attributes['calc_neutral_pep_mass']
#   start_scan=query.attributes['start_scan']
#   end_scan=query.attributes['end_scan']

#   run_summary_node=query.parent
#   # puts run_summary_node
#   search_summary_node=run_summary_node.find("./#{pepxml_ns_prefix}search_summary",pepxml_ns)[0]
#    # puts search_summary_node.attributes.each { |e| puts e }
#   search_engine=search_summary_node.attributes['search_engine']

#   # search_engine=""


#   raw_score=""
#   case search_engine
#   when /[Tt]andem/
#     search_score_nodes=top_search_hit.find("./#{pepxml_ns_prefix}search_score[@name=\"expect\"]",[pepxml_ns])
#     raw_score=search_score_nodes[0].attributes['value']
#   when /MS\-GF/
#     search_score_nodes=top_search_hit.find("./#{pepxml_ns_prefix}search_score[@name=\"EValue\"]",[pepxml_ns])
#     raw_score=search_score_nodes[0].attributes['value']    
#   end

  
#   pp_result=top_search_hit.find("./#{pepxml_ns_prefix}analysis_result/#{pepxml_ns_prefix}peptideprophet_result/@probability",pepxml_ns)
#   ip_result=top_search_hit.find("./#{pepxml_ns_prefix}analysis_result/#{pepxml_ns_prefix}interprophet_result/@probability",pepxml_ns)

#   peptide_prophet_prob=""
#   interprophet_prob=""
#   peptide_prophet_prob=pp_result[0].value if ( pp_result.length>0 )
#   interprophet_prob=ip_result[0].value if ( ip_result.length>0)
  
#   output_fh.write "#{protein}\t#{peptide}\t#{assumed_charge}\t#{calc_neutral_pep_mass}\t#{neutral_mass}\t#{retention_time}\t#{start_scan}\t#{end_scan}\t#{search_engine}\t#{raw_score}\t#{peptide_prophet_prob}\t#{interprophet_prob}\n"

# end

# output_fh.close