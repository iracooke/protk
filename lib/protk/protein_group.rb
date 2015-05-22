
require 'protk/peptide'
require 'protk/protein'
require 'protk/mzidentml_doc'
require 'protk/protxml_writer'

include LibXML


class ProteinGroup

	attr_accessor :group_number
	attr_accessor :group_probability
	attr_accessor :proteins

	class << self

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
		def from_mzid(groupnode,mzid_doc,minprob=0)

			group=new()

			group.group_number=groupnode.attributes['id'].split("_").last.to_i+1
			group.group_probability=mzid_doc.get_cvParam(groupnode,"MS:1002470").attributes['value'].to_f

			# require 'byebug';byebug

			protein_nodes=mzid_doc.get_proteins_for_group(groupnode)



			group_members = protein_nodes.select do |e| 
				mzid_doc.get_protein_probability(e)>=minprob
			end

			group.proteins = group_members.collect { |e| Protein.from_mzid(e,mzid_doc) }

			group
		end


		private :new
	end

	def initialize()

	end

	def as_protxml()
		node = XML::Node.new('protein_group')
    	node["group_number"] = self.group_number.to_s
    	node["group_probability"] = self.group_probability.to_s
    	self.proteins.each { |prot| node << prot.as_protxml }
    	node
	end


end