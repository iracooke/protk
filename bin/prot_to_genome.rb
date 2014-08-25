#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 3/8/2014
#
# 

require 'protk/constants'
require 'protk/fastadb'
require 'protk/gffdb'
require 'protk/protein'
require 'protk/peptide'
require 'protk/tool'
require 'libxml'
require 'bio'

include LibXML


class NoGFFEntryFoundError < StandardError
end

class ProteinNotInDBError < StandardError
end

class MultipleGFFEntriesForProteinError < StandardError
end

def parse_proteins(protxml_file)
  protxml_parser=XML::Parser.file(protxml_file)
  protxml_doc=protxml_parser.parse
  proteins = protxml_doc.find('.//protxml:protein','protxml:http://regis-web.systemsbiology.net/protXML')
  proteins.collect { |node| Protein.from_protxml(node)   }
end

def protein_id_to_gffid(protein_id,gff_idregex)
	return protein_id if gff_idregex.nil?
	return protein_id.match(/#{gff_idregex}/)[1]
end

def protein_id_to_genomeid(protein_id,genome_idregex)
	return protein_id if genome_idregex.nil?
	return protein_id.match(/#{genome_idregex}/)[1]
end

def protein_id_to_protdbid(protein_id)
	# return protein_id.sub(/^lcl\|/,"")
	return protein_id
end

def prepare_fasta(database_path,type)
  db_filename = nil
  case
  when Pathname.new(database_path).exist? # It's an explicitly named db  
    db_filename = Pathname.new(database_path).expand_path.to_s
  else
    db_filename=Constants.new.current_database_for_name(database_path)
  end


  db_indexfilename = type=='prot' ? "#{db_filename}.pin" : "#{db_filename}.nhr"

  if File.exist?(db_indexfilename)
    orf_lookup = FastaDB.new(db_filename)
  else
    orf_lookup = FastaDB.create(db_filename,db_filename,type)
  end
  orf_lookup
end



tool=Tool.new([:explicit_output,:debug])
tool.option_parser.banner = "Map proteins and peptides to genomic coordinates.\n\nUsage: prot_to_genome.rb [options] proteins.<protXML>"

tool.add_value_option(:database,nil,['-d filename','--database filename','Database used for ms/ms searches (Fasta Format)'])
tool.add_value_option(:genome,nil,['-g filename','--genome filename', 'Nucleotide sequences for scaffolds (Fasta Format)'])
tool.add_value_option(:coords_file,nil,['-c filename','--coords-file filename.gff3', 'A file containing genomic coordinates for predicted proteins and/or 6-frame translations'])
tool.add_boolean_option(:stack_charge_states,false,['--stack-charge-states','Different peptide charge states get separate gff entries'])
tool.add_value_option(:peptide_probability_threshold,0.95,['--threshold prob','Peptide Probability Threshold (Default 0.95)'])
tool.add_value_option(:protein_probability_threshold,0.99,['--prot-threshold prob','Protein Probability Threshold (Default 0.99)'])
tool.add_value_option(:gff_idregex,nil,['--gff-idregex pre','Regex with capture group for parsing gff ids from protein ids'])
tool.add_value_option(:genome_idregex,nil,['--genome-idregex pre','Regex with capture group for parsing genomic ids from protein ids'])

exit unless tool.check_options(true,[:database,:genome,:coords_file])

$protk = Constants.new
log_level = tool.debug ? "info" : "warn"
$protk.info_level= log_level


input_file=ARGV[0]

if tool.explicit_output
  output_fh=File.new("#{tool.explicit_output}",'w')  
else
  output_fh=$stdout
end

should_ = tool.debug || (output_fh!=$stdout)

input_protxml=ARGV[0]

gffdb = GFFDB.create(tool.coords_file) if tool.coords_file

genome_db = prepare_fasta(tool.genome,'nucl')
prot_db = prepare_fasta(tool.database,'prot')

proteins = parse_proteins(input_protxml)

proteins.each do |protein|

	begin
		# Get the full protein sequence
		#
		parsed_name_for_protdb = protein_id_to_protdbid(protein.protein_name)
		protein_entry = prot_db.get_by_id parsed_name_for_protdb
		raise ProteinNotInDBError if ( protein_entry == nil)

		protein.sequence = protein_entry.aaseq

		# Get the CDS and parent entries from the gff file
		#
		parsed_name_for_gffid = protein_id_to_gffid(protein.protein_name,tool.gff_idregex)
		gff_parent_entries = gffdb.get_by_id(parsed_name_for_gffid)
		raise NoGFFEntryFoundError if gff_parent_entries.nil? || gff_parent_entries.length==0
		raise MultipleGFFEntriesForProteinError if gff_parent_entries.length > 1

		gff_parent_entry = gff_parent_entries.first
		gff_cds_entries = gffdb.get_cds_by_parent_id(parsed_name_for_gffid)

		# Account for sixframe case. Parent is CDS and there are no children
		#
		gff_cds_entries=[gff_parent_entry] if gff_cds_entries.nil? && gff_parent_entry.feature=="CDS"

		protein.peptides.each do |peptide|
			peptide_entries = peptide.to_gff3_records(protein_entry.aaseq,gff_parent_entry,gff_cds_entries)
			peptide_entries.each do |peptide_entry|
				output_fh.write peptide_entry.to_s
			end
		end




	rescue NoGFFEntryFoundError
		$protk.log "No gff entry for #{parsed_name_for_gffid}", :info
	rescue ProteinNotInDBError
		$protk.log "No entry for #{parsed_name_for_protdb}", :info
	rescue MultipleGFFEntriesForProteinError
		$protk.log "Multiple entries in gff file for #{parsed_name_for_gffid}", :info
	rescue PeptideNotInProteinError
		$protk.log "A peptide was not found in its parent protein #{protein.protein_name}" , :warn
	end
end
