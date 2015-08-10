#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 24/6/2015
#
# Filters a pepxml file by removing or keeping only psms that match a filter
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'bio'
require 'libxml'

include LibXML

tool=Tool.new([:explicit_output,:debug])
tool.option_parser.banner = "Filter psms in a pepxml file.\n\nUsage: filter_psms.rb [options] expression file.pepxml"
tool.add_value_option(:filter,"protein",['-A','--attribute name',"Match expression against a specific search_hit attribute"])
tool.add_boolean_option(:check_alternative_proteins,false,['-C','--check-alternatives',"Also match expression against to alternative_proteins"])
tool.add_boolean_option(:reject_mode,false,['-R','--reject',"Keep mismatches instead of matches"])

exit unless tool.check_options(true,[:filter])

if ARGV.length!=2
  puts "Wrong number of arguments. You must supply a filter expression and a pepxml file"
  exit(1)
end

expressions=ARGV[0].split(",").map(&:strip)
input_file=ARGV[1]

$protk = Constants.instance
log_level = tool.debug ? "info" : "warn"
$protk.info_level= log_level


output_fh = tool.explicit_output!=nil ? File.new("#{tool.explicit_output}",'w') : $stdout

throw "Input file #{input_file} does not exist" unless File.exist? "#{input_file}"

XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

doc = XML::Document.file("#{input_file}")
reader = XML::Reader.document(doc)


# First print out the header (ie before spectrum_queries)
File.foreach("#{input_file}") do |line|  
  if line =~ /\<spectrum_query/
    break;
  else
    output_fh.write line
  end
end

pepxml_ns_prefix="xmlns:"
pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"

kept=0
deleted=0
scanned=0

while reader.read

  if reader.name == "spectrum_query"
    sq_node = reader.expand

    hits = sq_node.find("./#{pepxml_ns_prefix}search_result/#{pepxml_ns_prefix}search_hit[@hit_rank=\"1\"]",pepxml_ns)

    throw "More than one first ranked search hit" if hits.length>1
    throw "No search hit for spectrum_query" if hits.length==0

    hit = hits[0]

    has_match = expressions.collect { |expression|   (hit.attributes[tool.filter] =~ /#{expression}/) }.any?

    if !has_match && tool.check_alternative_proteins
      alts = hit.find("./#{pepxml_ns_prefix}alternative_protein",pepxml_ns)

      # Check alternative proteins
      alt_expr = alts.collect { |alt| expressions.collect { |expression| (alt.attributes[tool.filter] =~ /#{expression}/ )}}

      has_match = alt_expr.flatten.any?
    end

    if (has_match && !tool.reject_mode) || (!has_match && tool.reject_mode)  #&& (hit.attributes['hit_rank']=="1")
      kept+=1
      output_fh.write "#{sq_node}\n"
    else
      deleted+=1
    end

    scanned+=1

    reader.next_sibling
  end

end

output_fh.write "</msms_run_summary>\n</msms_pipeline_analysis>\n"

$protk.log "Kept #{kept} and deleted #{deleted}" , :info
