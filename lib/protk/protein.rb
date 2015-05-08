require 'protk/peptide'
require 'protk/mzidentml_doc'

include LibXML


class Protein

	attr_accessor :group_number
	attr_accessor :group_probability
	attr_accessor :probability
	attr_accessor :sequence
	attr_accessor :protein_name
	attr_accessor :n_indistinguishable_proteins
	attr_accessor :percent_coverage
	attr_accessor :peptides

	def as_protxml
		node = XML::Node.new('protein')
    	node['protein_name']=self.protein_name.to_s
    	node['n_indistinguishable_proteins']=self.n_indistinguishable_proteins.to_s
    	node['probability']=self.probability.to_s
    	node['percent_coverage']=self.percent_coverage.to_s
    	node['unique_stripped_peptides']=self.peptides.collect {|p| p.sequence }.join("+")
    	node['total_number_peptides']=self.peptides.length.to_s
    	self.peptides.each do |peptide|  
    		node<<peptide.as_protxml
    	end
    	node
	end


	class << self

		# <protein_group group_number="1" probability="1.0000">
		#       <protein protein_name="ACADV_MOUSE" n_indistinguishable_proteins="1" probability="1.0000" percent_coverage="9.9" unique_stripped_peptides="ELGAFGLQVPSELGGLGLSNTQYAR+GIVNEQFLLQR+SGELAVQALDQFATVVEAK+VAVNILNNGR" group_sibling_id="a" total_number_peptides="4" pct_spectrum_ids="0.41" confidence="1.00">
		#          <parameter name="prot_length" value="656"/>
		#          <annotation protein_description="Very long-chain specific acyl-CoA dehydrogenase, mitochondrial OS=Mus musculus GN=Acadvl PE=1 SV=3"/>
		#          <peptide peptide_sequence="SGELAVQALDQFATVVEAK" charge="1" initial_probability="0.9919" nsp_adjusted_probability="0.9981" weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="2.34" n_sibling_peptides_bin="5" n_instances="1" exp_tot_instances="0.99" is_contributing_evidence="Y" calc_neutral_pep_mass="1975.0340">
		#          </peptide>
		#          <peptide peptide_sequence="GIVNEQFLLQR" charge="1" initial_probability="0.9909" nsp_adjusted_probability="0.9979" weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="2.34" n_sibling_peptides_bin="5" n_instances="1" exp_tot_instances="0.99" is_contributing_evidence="Y" calc_neutral_pep_mass="1315.7250">
		#          </peptide>
		#          <peptide peptide_sequence="ELGAFGLQVPSELGGLGLSNTQYAR" charge="1" initial_probability="0.7792" nsp_adjusted_probability="0.9391" weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="2.55" n_sibling_peptides_bin="5" n_instances="1" exp_tot_instances="0.78" is_contributing_evidence="Y" calc_neutral_pep_mass="2576.3234">
		#          </peptide>
		#          <peptide peptide_sequence="VAVNILNNGR" charge="1" initial_probability="0.5674" nsp_adjusted_probability="0.8515" weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="2.76" n_sibling_peptides_bin="5" n_instances="1" exp_tot_instances="0.57" is_contributing_evidence="Y" calc_neutral_pep_mass="1068.6030">
		#          </peptide>
		#       </protein>
		# </protein_group>


		def from_protxml(xmlnode)
			prot=new()
			groupnode = xmlnode.parent
			prot.group_probability = groupnode['probability'].to_f
			prot.group_number = groupnode['group_number'].to_i
			prot.probability = xmlnode['probability'].to_f
			prot.protein_name = xmlnode['protein_name']
			prot.n_indistinguishable_proteins = xmlnode['n_indistinguishable_proteins'].to_i
			prot.percent_coverage = xmlnode['percent_coverage'].to_f

			peptide_nodes = xmlnode.find('protxml:peptide','protxml:http://regis-web.systemsbiology.net/protXML')
			prot.peptides = peptide_nodes.collect { |e| Peptide.from_protxml(e) }
			prot
		end


		# <ProteinAmbiguityGroup id="PAG_0">
		# 	<ProteinDetectionHypothesis id="PAG_0_1" dBSequence_ref="JEMP01000193.1_rev_g3500.t1 280755" passThreshold="false">
		# 		<PeptideHypothesis peptideEvidence_ref="PepEv_1">
		# 			<SpectrumIdentificationItemRef spectrumIdentificationItem_ref="SII_1_1"/>
		# 		</PeptideHypothesis>
		# 		<cvParam cvRef="PSI-MS" accession="MS:1002403" name="group representative"/>
		# 		<cvParam cvRef="PSI-MS" accession="MS:1002401" name="leading protein"/>
		# 		<cvParam cvRef="PSI-MS" accession="MS:1001093" name="sequence coverage" value="0.0"/>
		# 	</ProteinDetectionHypothesis>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1002470" name="PeptideShaker protein group score" value="0.0"/>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1002471" name="PeptideShaker protein group confidence" value="0.0"/>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1002545" name="PeptideShaker protein confidence type" value="Not Validated"/>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1002415" name="protein group passes threshold" value="false"/>
		# </ProteinAmbiguityGroup>


		# Note:
		# This is hacked together to work for a specific PeptideShaker output type
		# Refactor and properly respect cvParams for real conversion
		#
		def from_mzid(xmlnode)

			coverage_cvparam=""
			prot=new()
			groupnode = xmlnode.parent

			prot.group_number=groupnode.attributes['id'].split("_").last.to_i+1
			prot.protein_name=MzIdentMLDoc.get_dbsequence(xmlnode,xmlnode.attributes['dBSequence_ref']).attributes['accession']
			prot.n_indistinguishable_proteins=MzIdentMLDoc.get_proteins_for_group(groupnode).length
			prot.group_probability=MzIdentMLDoc.get_cvParam(groupnode,"MS:1002470").attributes['value'].to_f

			coverage_node=MzIdentMLDoc.get_cvParam(xmlnode,"MS:1001093")

			prot.percent_coverage=coverage_node.attributes['value'].to_f if coverage_node
			prot.probability = MzIdentMLDoc.get_protein_probability(xmlnode)
			# require 'byebug';byebug

			peptide_nodes=MzIdentMLDoc.get_peptides_for_protein(xmlnode)

			prot.peptides = peptide_nodes.collect { |e| Peptide.from_mzid(e) }
			prot
		end


		private :new
	end

	def initialize()

	end

	# Return just one peptide for each unique sequence choosing the peptide with highest probability
	#
	def representative_peptides()
		best_peptides={}
		self.peptides.each do |peptide|
			seq = peptide.sequence
			if best_peptides[seq].nil?
				best_peptides[seq]=peptide				
			else
				best_peptides[seq]=peptide if peptide.probability > best_peptides[seq].probability
			end
		end

		best_peptides.values
	end


end