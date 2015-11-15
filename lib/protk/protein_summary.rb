
require 'protk/mzidentml_doc'
require 'protk/protxml_writer'

include LibXML

# Represents the protein_summary node of a protXML document
# This is the root of the document
#
class ProteinSummary

	attr_accessor :reference_database
	attr_accessor :residue_substitution_list
	attr_accessor :source_files
	attr_accessor :source_files_alt
	attr_accessor :min_peptide_probability
	attr_accessor :min_peptide_weight
	attr_accessor :num_predicted_correct_prots
	attr_accessor :num_input_1_spectra
	attr_accessor :num_input_2_spectra
	attr_accessor :num_input_3_spectra
	attr_accessor :num_input_4_spectra
	attr_accessor :num_input_5_spectra
	attr_accessor :initial_min_peptide_prob
	attr_accessor :total_no_spectrum_ids
	attr_accessor :sample_enzyme

	attr_accessor :program_name
	attr_accessor :analysis_time
	attr_accessor :program_version


	class << self

		def from_mzid(mzid_doc)

			summary = new()
			# Things we cant retrieve
			summary.residue_substitution_list = ""
			summary.min_peptide_probability = ""
			summary.min_peptide_weight = ""
			summary.num_predicted_correct_prots = ""
			summary.num_input_1_spectra = ""
			summary.num_input_2_spectra = ""
			summary.num_input_3_spectra = ""
			summary.num_input_4_spectra = ""
			summary.num_input_5_spectra = ""
			summary.initial_min_peptide_prob = ""
			summary.total_no_spectrum_ids = ""			
			summary.analysis_time = ""

			db = mzid_doc.search_databases.first
			summary.reference_database = db.attributes['location']

			summary.source_files = mzid_doc.source_files.collect { |sf| sf.attributes['location'] }
			summary.source_files_alt = summary.source_files

			summary.sample_enzyme = mzid_doc.enzymes.first.attributes['name']
			if mzid_doc.enzymes.first.attributes['semiSpecific']=="true"
				summary.sample_enzyme = "semi#{summary.sample_enzyme}"
			end

			analysis_software = mzid_doc.analysis_software.first
			summary.program_name = analysis_software.attributes['name']
			summary.program_version = analysis_software.attributes['version']

			summary
		end


		private :new
	end

	def initialize()

	end

	def as_protxml()
		node = XML::Node.new('protein_summary_header')
		# node.space_preserve=true
		node["reference_database"] = self.reference_database
		node["min_peptide_probability"] = self.min_peptide_probability
		node["min_peptide_weight"] = self.min_peptide_weight
		node["num_predicted_correct_prots"] = self.num_predicted_correct_prots
		node["num_input_1_spectra"] = self.num_input_1_spectra
		node["num_input_2_spectra"] = self.num_input_2_spectra
		node["num_input_3_spectra"] = self.num_input_3_spectra
		node["num_input_4_spectra"] = self.num_input_4_spectra
		node["num_input_5_spectra"] = self.num_input_5_spectra
		node["initial_min_peptide_prob"] = self.initial_min_peptide_prob
		node["total_no_spectrum_ids"] = self.total_no_spectrum_ids
		node["sample_enzyme"] = self.sample_enzyme


		cnode = XML::Node.new('program_details')
		# node.space_preserve=true
		cnode["program_name"] = self.program_name
		cnode["analysis_time"] = self.analysis_time
		cnode["program_version"] = self.program_version
#		require 'byebug';byebug

		node << cnode

		# ddnode = XML::Node.new('dataset_derivation')
		# ddnode["generation_no"]="0"

		# node << ddnode

  	node
	end


end