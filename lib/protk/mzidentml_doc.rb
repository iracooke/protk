require 'libxml'

include LibXML

class MzIdentMLDoc < Object

	MZID_NS_PREFIX="mzidentml"
	MZID_NS='http://psidev.info/psi/pi/mzIdentML/1.1'

	def initialize(path)
		parser=XML::Parser.file(path)
		@document=parser.parse
	end


	def spectrum_queries
		@document.find("//#{MZID_NS_PREFIX}:SpectrumIdentificationResult","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end

	def peptide_evidence
		@document.find("//#{MZID_NS_PREFIX}:PeptideEvidence","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end

	def psms
		@document.find("//#{MZID_NS_PREFIX}:SpectrumIdentificationItem","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end	

	def protein_groups
		@document.find("//#{MZID_NS_PREFIX}:ProteinAmbiguityGroup","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end


	def proteins
		@document.find("//#{MZID_NS_PREFIX}:ProteinDetectionHypothesis","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end

	# Peptides are referenced in many ways in mzidentml. 
	# We define a "Peptide" as a peptide supporting a particular protein
	# Such peptides may encompass several PSM's
	#
	def peptides
		@document.find("//#{MZID_NS_PREFIX}:PeptideHypothesis","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end



	# -----------------------------------------------------------
	#
	# Class Level Utility methods for searching from a given node
	#
	# -----------------------------------------------------------

	def self.find(node,expression,root=false)
		pp = root ? "//" : "./"
		node.find("#{pp}#{MZID_NS_PREFIX}:#{expression}","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end


	def self.get_cvParam(mzidnode,accession)
		self.find(mzidnode,"cvParam[@accession=\'#{accession}\']")[0]
	end

	def self.get_dbsequence(mzidnode,accession)
		self.find(mzidnode,"DBSequence[@accession=\'#{accession}\']",true)[0]
	end

	# As per PeptideShaker. Assume group probability used for protein if it is group rep otherwise 0
	def self.get_protein_probability(protein_node)

		#MS:1002403
		is_group_representative=(self.get_cvParam(protein_node,"MS:1002403")!=nil)
		if is_group_representative
			return 	self.get_cvParam(protein_node.parent,"MS:1002470").attributes['value'].to_f*0.01
		else
			return 0
		end
	end

	def self.get_proteins_for_group(group_node)
		self.find(group_node,"ProteinDetectionHypothesis")
	end

	# def self.get_sister_proteins(protein_node)
	# 	self.find(protein_node.parent,"ProteinDetectionHypothesis")
	# end

	def self.get_peptides_for_protein(protein_node)
		self.find(protein_node,"PeptideHypothesis")
	end

	# <PeptideHypothesis peptideEvidence_ref="PepEv_1">
	# 	<SpectrumIdentificationItemRef spectrumIdentificationItem_ref="SII_1_1"/>
	# </PeptideHypothesis>
	def self.get_best_psm_for_peptide(peptide_node)

		best_score=-1
		best_psm=nil
		self.find(peptide_node,"SpectrumIdentificationItemRef").each do |id_ref_node|  
			id_ref = id_ref_node.attributes['spectrumIdentificationItem_ref']
			psm_node = self.find(peptide_node,"SpectrumIdentificationItem[@id=\'#{id_ref}\']",true)[0]
			score = self.get_cvParam(psm_node,"MS:1002466")['value'].to_f
			if score>best_score
				best_psm=psm_node
				best_score=score
			end
		end
		best_psm
	end

	def self.get_sequence_for_peptide(peptide_node)
		evidence_ref = peptide_node.attributes['peptideEvidence_ref']
		pep_ref = peptide_node.find("//#{MZID_NS_PREFIX}:PeptideEvidence[@id=\'#{evidence_ref}\']","#{MZID_NS_PREFIX}:#{MZID_NS}")[0].attributes['peptide_ref']
		peptide=peptide_node.find("//#{MZID_NS_PREFIX}:Peptide[@id=\'#{pep_ref}\']","#{MZID_NS_PREFIX}:#{MZID_NS}")[0]
		# require 'byebug';byebug
		peptide.find("./#{MZID_NS_PREFIX}:PeptideSequence","#{MZID_NS_PREFIX}:#{MZID_NS}")[0].content
	end

	def self.get_sequence_for_psm(psm_node)
		pep_ref = psm_node.attributes['peptide_ref']
		peptide=psm_node.find("//#{MZID_NS_PREFIX}:Peptide[@id=\'#{pep_ref}\']","#{MZID_NS_PREFIX}:#{MZID_NS}")[0]
		peptide.find("./#{MZID_NS_PREFIX}:PeptideSequence","#{MZID_NS_PREFIX}:#{MZID_NS}")[0].content
	end

	def self.get_peptide_evidence_from_psm(psm_node)
		pe_nodes = []
		self.find(psm_node,"PeptideEvidenceRef").each do |pe_node|
			ev_id=pe_node.attributes['peptideEvidence_ref']   
			pe_nodes << self.find(pe_node,"PeptideEvidence[@id=\'#{ev_id}\']",true)[0]
		end
		pe_nodes
	end








end