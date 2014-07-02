#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Convert a protein/peptide xml file to sqlite database
#
#

require 'libxml'
require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'protk/fastadb'
require 'sqlite3'
require 'protk/mzml_parser'

include LibXML

def prepare_fasta(database_path,type)

  db_filename = nil
  case
  when Pathname.new(database_path).exist? # It's an explicitly named db  
    db_filename = Pathname.new(database_path).expand_path.to_s
  else
    db_filename=Constants.new.current_database_for_name(database_path)
  end

  db_indexfilename = "#{db_filename}.pin"

  if File.exist?(db_indexfilename)
    puts "Using existing indexed database"
    orf_lookup = FastaDB.new(db_filename)
  else
    puts "Indexing database"
    orf_lookup = FastaDB.create(db_filename,db_filename,type)
  end
  orf_lookup
end

def get_fasta_record(protein_name,fastadb)
#  puts "Looking up #{protein_name}"
  entry = fastadb.get_by_id protein_name
  if ( entry == nil)
    puts "Failed lookup for #{protein_name}"
    raise KeyError
  end
  entry
end

def initialize_db()
	result = $outputdb.execute <<-SQL
	  CREATE TABLE ProteinGroups (
	    ID INT, 
	    Probability REAL
	  );
	SQL

	result = $outputdb.execute <<-SQL
	  CREATE TABLE Proteins (
	    ID INT,
	    ProteinGroupID INT,
	    Probability REAL,
	    Name TEXT,
	    Description TEXT,
	    Coverage REAL,
	    NumPeptides INT,
	    Indistinguishables TEXT,
	    Sequence TEXT
	  );
	SQL

	result = $outputdb.execute <<-SQL
	  CREATE TABLE Peptides (
	    ID INT,
	    ProteinID INT,
	    Probability REAL,
	    Sequence TEXT,
	    Start INT,
	    End INT,
	    ModifiedSequence TEXT
	  );
	SQL

	# This has the role of a join table for the Peptides <-> Spectra many to many relationship
	result = $outputdb.execute <<-SQL
		CREATE TABLE PeptideSpectrumMatches (
	    PeptideSequence TEXT,
	    PeptideModifiedSequence TEXT,
	    SpectrumID INT,
	    ScanNum INT,
	    RetentionTime REAL,
	    PrecursorNeutralMass REAL,
	    MassDeviation REAL,
	    PrevAA TEXT,
	    NextAA TEXT
	  );
	SQL

	result = $outputdb.execute <<-SQL
		CREATE TABLE Spectra (
			ID INTEGER PRIMARY KEY,
			MZData TEXT,
			IntensityData TEXT,
			PrecursorMass REAL,
			PrecursorCharge INT,
			SpectrumType INT,
			SpectrumTitle TEXT
		);
	SQL

end

def insert_protein_group(group_node)
	group_number=group_node.attributes['group_number']
	group_prob=group_node.attributes['probability']
	$outputdb.execute <<-SQL
		INSERT INTO ProteinGroups(ID,Probability) VALUES(
			#{group_number},#{group_prob}
		);
	SQL

	proteins=group_node.find("./#{$protxml_ns_prefix}protein", $protxml_ns)

	proteins.each do |protein|
		insert_protein(protein,group_number)
	end
end

def protein_dbid_from_name(protein_name)
	protein_name #TODO: Allow user defined regex to parse this
end

def insert_protein(protein,group_id)

	indis_proteins=protein.find("./#{$protxml_ns_prefix}indistinguishable_protein", $protxml_ns)
	indis_proteins_summary=""
	indis_proteins.each { |iprot| indis_proteins_summary<<"#{iprot.attributes['protein_name']};" }

	annot_descr=protein.find("./#{$protxml_ns_prefix}annotation[@protein_description]", $protxml_ns)


	protein_prob=protein.attributes['probability']
	protein_name=protein.attributes['protein_name']

	begin
		protein_description=annot_descr[0].attributes['protein_description'].chomp.gsub("'","")
	rescue
		puts "No protein_description"
	end
	protein_coverage=protein.attributes['percent_coverage']
	protein_npep = protein.attributes['total_number_peptides']
	protein_indis = indis_proteins_summary

	protein_coverage="NULL" unless protein_coverage
	protein_indis="NULL" unless protein_indis
	protein_description="NULL" unless protein_description

	if $fasta_lookup
		begin
			entry=get_fasta_record(protein_name,$fasta_lookup)
			protein_seq=entry.aaseq
		rescue
			puts "Warning: No entry found for #{protein_name}"
			protein_seq="NULL"
		end
	end

	begin
		$outputdb.execute <<-SQL
		INSERT INTO Proteins(ID,ProteinGroupID,Probability,Name,Description,Coverage,NumPeptides,Indistinguishables,Sequence) 
		VALUES(#{$protein_id},#{group_id},#{protein_prob},\'#{protein_name}\',\'#{protein_description}\',#{protein_coverage},
		#{protein_npep},\'#{protein_indis}\','#{protein_seq}');
		SQL
	rescue
		throw "Unable to insert #{protein_description}\n"
	end
	peptides=protein.find("./#{$protxml_ns_prefix}peptide",$protxml_ns)

	peptides.each do |peptide|  
		insert_peptide(peptide,$protein_id,protein_seq)
	end
	$protein_id+=1
end

def insert_peptide(peptide,protein_id,protein_seq)
	nsp_adjusted_probability=peptide.attributes['nsp_adjusted_probability']
	sequence=peptide.attributes['peptide_sequence']

	start_pos="NULL"
	end_pos="NULL"
	begin
		if protein_seq!="NULL"
			start_pos = protein_seq.index(sequence)
			end_pos = start_pos+sequence.length
		end
	rescue
		puts "Unable to locate peptide #{sequence} in protein #{protein_seq} for #{$protein_id}\n"
		start_pos="NULL"
		end_pos="NULL"
	end
	mod_info=peptide.find("./#{$protxml_ns_prefix}modification_info",$protxml_ns)

	throw "More than one modification_info object for a peptide" unless mod_info.length<=1
	mod_seq=format_modified_peptide(mod_info)

	$outputdb.execute <<-SQL
		INSERT INTO Peptides(ID,ProteinID,Probability,Sequence,Start,End,ModifiedSequence)
		VALUES(#{$peptide_id},#{protein_id},#{nsp_adjusted_probability},\'#{sequence}\',
		#{start_pos},#{end_pos},\'#{mod_seq}\')
	SQL
	$peptide_id+=1

end

def format_modified_peptide(mod_info)
	mod_seq="NULL"
	if mod_info.length==1
		mod_seq=mod_info[0].attributes['modified_peptide']
		mod_seq.gsub!(/\[/,"\{")
		mod_seq.gsub!(/\]/,"\}")
	end
	mod_seq
end

def insert_psms_from_file(filepath)
	$pepxml_ns_prefix="xmlns:"
	$pepxml_ns="xmlns:http://regis-web.systemsbiology.net/pepXML"

	pepxml_parser=XML::Parser.file("#{filepath}")
	puts "Parsing #{filepath}"
	pepxml_doc=pepxml_parser.parse
	if not pepxml_doc.root.namespaces.default
  		$pepxml_ns_prefix=""
  		$pepxml_ns=nil
	end

	matched_spectra=[]

	spectrum_queries=pepxml_doc.find("//#{$pepxml_ns_prefix}spectrum_query", $pepxml_ns)

	spectrum_queries.each do |query| 

		spectrum_name = query.attributes['spectrum'].chomp.gsub(/\.0+/,"\.").sub(/\.\d+$/,"")

		start_scan=query.attributes['start_scan'].to_i
		end_scan=query.attributes['end_scan'].to_i
		throw "Don't know how to deal with multi scan spectra" unless start_scan==end_scan

		retention_time=query.attributes['retention_time_sec'].chomp.to_f
		neutral_mass=query.attributes['precursor_neutral_mass'].to_f
		assumed_charge=query.attributes['assumed_charge'].to_i


		top_search_hit=query.find("./#{$pepxml_ns_prefix}search_result/#{$pepxml_ns_prefix}search_hit",$pepxml_ns)[0]
		peptide=top_search_hit.attributes['peptide']

		mod_info=top_search_hit.find("./#{$protxml_ns_prefix}modification_info",$protxml_ns)

		throw "More than one modification_info object for a peptide" unless mod_info.length<=1
		modified_peptide=format_modified_peptide(mod_info)

		calc_neutral_pep_mass=top_search_hit.attributes['calc_neutral_pep_mass'].to_f
		massdiff = top_search_hit.attributes['massdiff'].to_f
		prevaa = top_search_hit.attributes['peptide_prev_aa']
		nextaa = top_search_hit.attributes['peptide_next_aa']

		spectrum_name="NULL" unless spectrum_name
		retention_time="NULL" unless retention_time
		assumed_charge="NULL" unless assumed_charge
		calc_neutral_pep_mass="NULL" unless calc_neutral_pep_mass
		massdiff = "NULL" unless massdiff
		prevaa = "NULL" unless prevaa
		nextaa = "NULL" unless nextaa


		$outputdb.execute <<-SQL
			INSERT INTO PeptideSpectrumMatches(PeptideSequence,PeptideModifiedSequence,SpectrumID,ScanNum,RetentionTime,PrecursorNeutralMass,MassDeviation,PrevAA,NextAA)
			VALUES('#{peptide}','#{modified_peptide}','#{spectrum_name}','#{start_scan}','#{retention_time.to_f}'\
			,'#{calc_neutral_pep_mass}','#{massdiff}','#{prevaa}','#{nextaa}')
		SQL

		matched_spectra<<{:name => spectrum_name, :scan_num => start_scan}

	end

	matched_spectra
end


def lookup_spectra_from_files(file_list,matched_spectra)

	titles_to_match = matched_spectra.collect { |s| s[:name] }

	# require 'debugger';debugger

	queries_with_spectra=Array.new.replace(titles_to_match)

	num_matched=0
	total_spectra=0

	file_list.each do |file|
		mzml_parser = MzMLParser.new(file)

		spec = mzml_parser.next_spectrum


		while (spec) do
			total_spectra+=1
			if titles_to_match.include? spec[:title]
				num_matched+=1
				queries_with_spectra.delete(spec[:title])

				$outputdb.execute <<-SQL
					INSERT INTO Spectra(MZData,IntensityData,SpectrumTitle,PrecursorMass)
					VALUES('#{spec[:mz]}','#{spec[:intensity]}','#{spec[:title]}','#{spec[:precursormz]}')
				SQL

			else
				# require 'debugger';debugger
				# puts "Unmatched spectrum #{spec[:title]}"
			end
			spec = mzml_parser.next_spectrum
		end

	end
	puts "Found #{num_matched} matching spectra"
	puts "Total in spectrum files #{total_spectra}"
	puts "Total psms #{titles_to_match.length}"
	puts "Unmatched psms #{queries_with_spectra.length}"



end

# Setup specific command-line options for this tool. Other options are inherited from ProphetTool
#
tool=Tool.new([:explicit_output,:over_write])
tool.option_parser.banner = "Convert a protXML file to a sqlite database.\n\nUsage: protxml_to_psql.rb [options] file1.protXML"

tool.add_value_option(:database,nil,['-d','--database path','A Fasta file where full protein sequences can be looked up'])

# require 'debugger';debugger

exit unless tool.check_options(true,[:explicit_output])

input_file=ARGV.shift


if File.exists? tool.explicit_output
	throw "Cant overwrite existing db #{tool.explicit_output}" unless tool.over_write
	File.delete(tool.explicit_output)		
end

$fasta_lookup=nil
if tool.database
	$fasta_lookup=prepare_fasta(tool.database,'prot')
end

$outputdb = SQLite3::Database.new tool.explicit_output

initialize_db

XML::Error.set_handler(&XML::Error::QUIET_HANDLER)

protxml_parser=XML::Parser.file("#{input_file}")

$protxml_ns_prefix="xmlns:"
$protxml_ns="xmlns:http://regis-web.systemsbiology.net/protXML"


protxml_doc=protxml_parser.parse
if not protxml_doc.root.namespaces.default
  $protxml_ns_prefix=""
  $protxml_ns=nil
end

$protein_id=0
$peptide_id=0

headers_with_inputs=protxml_doc.find("//#{$protxml_ns_prefix}protein_summary_header[@source_files]",$protxml_ns)

matched_spectra=[]

headers_with_inputs.each do |header|  
	pepxml_files = header.attributes['source_files'].split(",")
	pepxml_files.each do |pepxml_file|
		matched_spectra.concat insert_psms_from_file(pepxml_file)
	end
end

lookup_spectra_from_files(ARGV.collect { |file| file.chomp },matched_spectra)

protein_groups=protxml_doc.find("//#{$protxml_ns_prefix}protein_group", $protxml_ns)

protein_groups.each do |g| 
	insert_protein_group(g)
end

