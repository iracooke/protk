
require 'protk/mzidentml_doc'
require 'protk/psm'
require 'protk/physical_constants'

include LibXML


# <spectrum_query spectrum="mr176-BSA100fmole_BA3_01_8167.00003.00003.2" start_scan="3" end_scan="3" 
#precursor_neutral_mass="1398.7082" assumed_charge="2" index="2" experiment_label="mr176">
# <search_result>
# <search_hit hit_rank="1" peptide="SQVFQLESTFDV" peptide_prev_aa="R" peptide_next_aa="K" protein="tr|Q90853|Q90853_CHICK" protein_descr="Homeobox protein OS=Gallus gallus GN=GH6 PE=2 SV=1" num_tot_proteins="1" num_matched_ions="9" tot_num_ions="22" calc_neutral_pep_mass="1380.6557" massdiff="18.053" num_tol_term="1" num_missed_cleavages="0" is_rejected="0">
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

class SpectrumQuery


	attr_accessor :spectrum_title
	attr_accessor :retention_time
	# attr_accessor :precursor_neutral_mass
	# attr_accessor :assumed_charge

	# attr_accessor :index
	attr_accessor :psms

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

		def from_mzid(query_node)
			query = new()
			query.spectrum_title = MzIdentMLDoc.get_cvParam(query_node,"MS:1000796")['value'].to_s
			query.retention_time = MzIdentMLDoc.get_cvParam(query_node,"MS:1000894")['value'].to_f
			items = MzIdentMLDoc.find(query_node,"SpectrumIdentificationItem")
			query.psms = items.collect { |item| PSM.from_mzid(item) }
			query
		end


		private :new
	end

	def initialize()

	end

# <spectrum_query spectrum="SureshVp1to10_BAF.00833.00833.1" start_scan="833" end_scan="833" 
# precursor_neutral_mass="1214.5937" assumed_charge="1" index="3222">
# <search_result>

	def as_pepxml()
		node = XML::Node.new('spectrum_query')
		node['spectrum']=self.spectrum_title
		node['retention_time_sec']=self.retention_time.to_s


		# Use the first psm to populate spectrum level values
		first_psm=self.psms.first

		c=first_psm.charge

		node['precursor_neutral_mass']=(first_psm.experimental_mz*c-c*HYDROGEN_MASS).to_s
		node['assumed_charge']=c.to_s


		self.psms.each do |psm|  
			node << psm.as_pepxml
		end
    	node
	end


end