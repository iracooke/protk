
require 'protk/mzidentml_doc'
require 'libxml'

include LibXML


class String
  def to_bool
    return true if self == true || self =~ (/^(true|t|yes|y|1)$/i)
    return false if self == false || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new("invalid value for Boolean: \"#{self}\"")
  end
end

class PeptideEvidence
	attr_accessor :peptide_prev_aa
	attr_accessor :peptide_next_aa
	attr_accessor :protein
	attr_accessor :protein_descr
	# attr_accessor :peptide_sequence
	attr_accessor :is_decoy

# <PeptideEvidence isDecoy="false" pre="K" post="G" start="712"
#     end="722" peptide_ref="KSPVYKVHFTR"
#     dBSequence_ref="JEMP01000193.1_rev_g3500.t1" id="PepEv_1" />
	class << self

		def from_mzid(pe_node,mzid_doc)
			pe = new()
			pe.peptide_prev_aa=pe_node.attributes['pre']
			pe.peptide_next_aa=pe_node.attributes['post']
			pe.is_decoy=pe_node.attributes['isDecoy'].to_bool

			# peptide_ref = pe_node.attributes['peptide_ref']
			prot_ref = pe_node.attributes['dBSequence_ref']
			# pep_node = MzIdentMLDoc.find(pe_node,"Peptide[@id=\'#{peptide_ref}\']",true)[0]
			prot_node = MzIdentMLDoc.find(pe_node,"DBSequence[@id=\'#{prot_ref}\']",true)[0]


			# <DBSequence id="JEMP01000193.1_rev_g3500.t1"
			# accession="JEMP01000193.1_rev_g3500.t1"
			# searchDatabase_ref="SearchDB_1">
			#   <cvParam cvRef="PSI-MS" accession="MS:1001088"
			#   name="protein description" value="280755|283436" />
			# </DBSequence>
			pe.protein=prot_node.attributes['accession']
			pe.protein_descr=mzid_doc.get_cvParam(prot_node,"MS:1001088")['value']


			# pe.peptide_sequence=pep_node

			pe
		end


		private :new
	end

	def initialize()

	end

#	<alternative_protein protein="lcl|JEMP01000005.1_rev_g4624.t1" 
# protein_descr="652491|654142" num_tol_term="2" peptide_prev_aa="K" peptide_next_aa="Y"/>
# We use this only for alternative_proteins
# The first peptide_evidence item is baked into the attributes of a spectrum_query
	def as_pepxml()
		alt_node = XML::Node.new('alternative_protein')
		alt_node['protein']=self.protein
		alt_node['protein_descr']=self.protein_descr
		alt_node['peptide_prev_aa']=self.peptide_prev_aa
		alt_node['peptide_next_aa']=self.peptide_next_aa


		alt_node
	end

end

# <spectrum_query spectrum="mr176-BSA100fmole_BA3_01_8167.00003.00003.2" start_scan="3" end_scan="3" 
#precursor_neutral_mass="1398.7082" assumed_charge="2" index="2" experiment_label="mr176">
# <search_result>
# <search_hit hit_rank="1" peptide="SQVFQLESTFDV" peptide_prev_aa="R" peptide_next_aa="K" protein="tr|Q90853|Q90853_CHICK" 
# protein_descr="Homeobox protein OS=Gallus gallus GN=GH6 PE=2 SV=1" num_tot_proteins="1" 
# num_matched_ions="9" tot_num_ions="22" calc_neutral_pep_mass="1380.6557" massdiff="18.053" num_tol_term="1" 
# num_missed_cleavages="0" is_rejected="0">
# <search_score name="hyperscore" value="23.9"/>
# <search_score name="nextscore" value="19.3"/>
# <search_score name="bscore" value="9.6"/>
# <search_score name="yscore" value="7.6"/>
# <search_score name="cscore" value="0"/>
# <search_score name="zscore" value="0"/>
# <search_score name="ascore" value="0"/>
# <search_score name="xscore" value="0"/>
# <search_score name="expect" value="0.099"/>
# <analysis_result analysis="peptideprophet">
# <peptideprophet_result probability="0.9997" all_ntt_prob="(0.0000,0.9997,0.9999)">
# <search_score_summary>
# <parameter name="fval" value="2.3571"/>
# <parameter name="ntt" value="1"/>
# <parameter name="nmc" value="0"/>
# <parameter name="massd" value="18.053"/>
# </search_score_summary>
# </peptideprophet_result>
# </analysis_result>
# </search_hit>
# </search_result>
# </spectrum_query>

class PSM


	attr_accessor :peptide
	attr_accessor :calculated_mz
	attr_accessor :experimental_mz
	attr_accessor :charge

	attr_accessor :scores
	attr_accessor :peptide_evidence

	class << self

		# <SpectrumIdentificationResult spectraData_ref="ma201_Vp_1-10.mzML.mgf"
		# spectrumID="index=3152" id="SIR_1">
		#   <SpectrumIdentificationItem passThreshold="false"
		#   rank="1" peptide_ref="KSPVYKVHFTR"
		#   calculatedMassToCharge="1360.7615466836999"
		#   experimentalMassToCharge="1362.805053710938"
		#   chargeState="1" id="SII_1_1">
		#     <PeptideEvidenceRef peptideEvidence_ref="PepEv_1" />
		#     <Fragmentation>
		#       <IonType charge="1" index="1 4">
		#         <FragmentArray measure_ref="Measure_MZ"
		#         values="175.2081208 560.3388993" />
		#         <FragmentArray measure_ref="Measure_Int"
		#         values="94.0459823608 116.2766723633" />
		#         <FragmentArray measure_ref="Measure_Error"
		#         values="0.08916864948798775 0.0449421494880653" />
		#         <cvParam cvRef="PSI-MS" accession="MS:1001220"
		#         name="frag: y ion" />
		#       </IonType>
		#     </Fragmentation>
		#     <cvParam cvRef="PSI-MS" accession="MS:1002466"
		#     name="PeptideShaker PSM score" value="0.0" />
		#     <cvParam cvRef="PSI-MS" accession="MS:1002467"
		#     name="PeptideShaker PSM confidence" value="0.0" />
		#     <cvParam cvRef="PSI-MS" accession="MS:1002052"
		#     name="MS-GF:SpecEValue" value="1.4757611E-6" />
		#     <cvParam cvRef="PSI-MS" accession="MS:1001117"
		#     name="theoretical mass" value="1360.7615466836999" />
		#     <cvParam cvRef="PSI-MS" accession="MS:1002543"
		#     name="PeptideShaker PSM confidence type"
		#     value="Not Validated" />
		#   </SpectrumIdentificationItem>
		#   <cvParam cvRef="PSI-MS" accession="MS:1000796"
		#   name="spectrum title"
		#   value="Suresh Vp 1 to 10_BAF.3535.3535.1" />
		#   <cvParam cvRef="PSI-MS" accession="MS:1000894"
		#   name="retention time" value="6855.00001" unitCvRef="UO"
		#   unitAccession="UO:0000010" unitName="seconds" />
		# </SpectrumIdentificationResult>



		def from_mzid(psm_node,mzid_doc)
			psm = new()
			psm.peptide = mzid_doc.get_sequence_for_psm(psm_node)
			peptide_evidence_nodes = mzid_doc.get_peptide_evidence_from_psm(psm_node)
			psm.peptide_evidence = peptide_evidence_nodes.collect { |pe| PeptideEvidence.from_mzid(pe,mzid_doc) }

			psm.calculated_mz = psm_node.attributes['calculatedMassToCharge'].to_f
			psm.experimental_mz = psm_node.attributes['experimentalMassToCharge'].to_f
			psm.charge = psm_node.attributes['chargeState'].to_i

			psm
		end


		private :new
	end

	def initialize()

	end

	# <search_hit hit_rank="1" peptide="GGYNQDGGSGGGYQGGGGYSGGGGGYQGGQR" 
	# peptide_prev_aa="R" peptide_next_aa="N" 
	# protein="lcl|JEMP01000008.1_fwd_g5144.t1" 
	# num_tot_proteins="1" 
	# calc_neutral_pep_mass="2768.11967665812" 
	# massdiff="0.120361328125" 
	# protein_descr="4860|5785" 
	# num_tol_term="2" 
	# num_missed_cleavages="0">

	# From what I can tell, search_hit is always trivially wrapped in search_result 1:1
	#
	def as_pepxml()
		hit_node = XML::Node.new('search_hit')
		hit_node['peptide']=self.peptide.to_s

		# require 'byebug';byebug
		first_evidence = self.peptide_evidence.first

		hit_node['peptide_prev_aa']=first_evidence.peptide_prev_aa
		hit_node['peptide_next_aa']=first_evidence.peptide_next_aa
		hit_node['protein']=first_evidence.protein
		hit_node['protein_descr']=first_evidence.protein_descr

		hit_node['num_tot_proteins']=self.peptide_evidence.length.to_s

		alt_evidence = peptide_evidence.drop(1)
		alt_evidence.each { |ae| hit_node << ae.as_pepxml }

		result_node = XML::Node.new('search_result')
		result_node << hit_node
		result_node
	end


end