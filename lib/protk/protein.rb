require 'protk/peptide'

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
		private :new
	end

	def initialize()

	end

end