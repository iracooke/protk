require 'libxml'

include LibXML

class MzIdentMLDoc < Object

	MZID_NS_PREFIX="mzidentml"
	MZID_NS='http://psidev.info/psi/pi/mzIdentML/1.1'

	attr :psms_cache
	attr :db_sequence_cache

	def psms_cache
		if !@psms_cache
			@psms_cache={}
			Constants.instance.log "Generating psm index" , :debug
			self.psms.each do |spectrum_identification_item|  
				@psms_cache[spectrum_identification_item.attributes['id']]=spectrum_identification_item
			end
		end
		@psms_cache
	end

	def dbsequence_cache
		if !@dbsequence_cache
			@dbsequence_cache={}
			Constants.instance.log "Generating DB index" , :debug
			self.dbsequences.each do |db_sequence|  
				@dbsequence_cache[db_sequence.attributes['accession']]=db_sequence
			end
		end
		@dbsequence_cache
	end

	def initialize(path)
		parser=XML::Parser.file(path)
		@document=parser.parse
	end

	def source_files
		@document.find("//#{MZID_NS_PREFIX}:SourceFile","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end

	def search_databases
		@document.find("//#{MZID_NS_PREFIX}:SearchDatabase","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end

	def enzymes
		@document.find("//#{MZID_NS_PREFIX}:Enzyme","#{MZID_NS_PREFIX}:#{MZID_NS}")
	end

	def analysis_software
		@document.find("//#{MZID_NS_PREFIX}:AnalysisSoftware","#{MZID_NS_PREFIX}:#{MZID_NS}")
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

	def dbsequences
		@document.find("//#{MZID_NS_PREFIX}:DBSequence","#{MZID_NS_PREFIX}:#{MZID_NS}")		
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

	def find(node,expression,root=false)
		MzIdentMLDoc.find(node,expression,root)
	end


	def get_cvParam(mzidnode,accession)
		self.find(mzidnode,"cvParam[@accession=\'#{accession}\']")[0]
	end

	def get_dbsequence(mzidnode,accession)
		self.dbsequence_cache[accession]
		# self.find(mzidnode,"DBSequence[@accession=\'#{accession}\']",true)[0]
	end

	# As per PeptideShaker. Assume group probability used for protein if it is group rep otherwise 0
	def get_protein_probability(protein_node)

		#MS:1002403
		is_group_representative=(self.get_cvParam(protein_node,"MS:1002403")!=nil)
		if is_group_representative
			return 	self.get_cvParam(protein_node.parent,"MS:1002470").attributes['value'].to_f*0.01
		else
			return 0
		end
	end

	# Memoized because it gets called for every protein in a group
	def get_proteins_for_group(group_node)
		@proteins_for_group_cache ||= Hash.new do |h,key|
			h[key] = self.find(group_node,"ProteinDetectionHypothesis")
		end
		@proteins_for_group_cache[group_node]
	end

	# def self.get_sister_proteins(protein_node)
	# 	self.find(protein_node.parent,"ProteinDetectionHypothesis")
	# end

	def get_peptides_for_protein(protein_node)
		self.find(protein_node,"PeptideHypothesis")
	end

	# <PeptideHypothesis peptideEvidence_ref="PepEv_1">
	# 	<SpectrumIdentificationItemRef spectrumIdentificationItem_ref="SII_1_1"/>
	# </PeptideHypothesis>
	def get_best_psm_for_peptide(peptide_node)
		best_score=nil
		best_psm=nil
		spectrumidrefs = self.find(peptide_node,"SpectrumIdentificationItemRef")
		Constants.instance.log "Searching from among #{spectrumidrefs.length} for best psm" , :debug

		spectrumidrefs.each do |id_ref_node|  
			id_ref = id_ref_node.attributes['spectrumIdentificationItem_ref']
			# psm_node = self.find(peptide_node,"SpectrumIdentificationItem[@id=\'#{id_ref}\']",true)[0]
			psm_node = self.psms_cache[id_ref]
			score = self.get_cvParam(psm_node,"MS:1002466")['value'].to_f
			if ( best_score == nil ) || ( score > best_score )
				best_psm=psm_node
				best_score=score
			end
		end
		best_psm
	end

	def get_sequence_for_peptide(peptide_node)
		evidence_ref = peptide_node.attributes['peptideEvidence_ref']
		pep_ref = peptide_node.find("//#{MZID_NS_PREFIX}:PeptideEvidence[@id=\'#{evidence_ref}\']","#{MZID_NS_PREFIX}:#{MZID_NS}")[0].attributes['peptide_ref']
		peptide=peptide_node.find("//#{MZID_NS_PREFIX}:Peptide[@id=\'#{pep_ref}\']","#{MZID_NS_PREFIX}:#{MZID_NS}")[0]
		# require 'byebug';byebug
		peptide.find("./#{MZID_NS_PREFIX}:PeptideSequence","#{MZID_NS_PREFIX}:#{MZID_NS}")[0].content
	end

	def get_sequence_for_psm(psm_node)
		pep_ref = psm_node.attributes['peptide_ref']
		peptide=psm_node.find("//#{MZID_NS_PREFIX}:Peptide[@id=\'#{pep_ref}\']","#{MZID_NS_PREFIX}:#{MZID_NS}")[0]
		peptide.find("./#{MZID_NS_PREFIX}:PeptideSequence","#{MZID_NS_PREFIX}:#{MZID_NS}")[0].content
	end

	def get_peptide_evidence_from_psm(psm_node)
		pe_nodes = []
		self.find(psm_node,"PeptideEvidenceRef").each do |pe_node|
			ev_id=pe_node.attributes['peptideEvidence_ref']   
			pe_nodes << self.find(pe_node,"PeptideEvidence[@id=\'#{ev_id}\']",true)[0]
		end
		pe_nodes
	end








end