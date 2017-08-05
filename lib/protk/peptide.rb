require 'libxml'
require 'bio'
require 'protk/bio_gff3_extensions'
require 'protk/mzidentml_doc'
require 'protk/error'
require 'protk/peptide_mod'
# require 'protk/indistinguishable_peptide'

include LibXML

class PeptideNotInProteinError < ProtkError
end


class Peptide

	# Stripped sequence (no modifications)
	attr_accessor :sequence
	attr_accessor :protein_name
	attr_accessor :charge
	attr_accessor :probability
	attr_accessor :theoretical_neutral_mass
	attr_accessor :modifications
	attr_accessor :modified_sequence
	attr_accessor :indistinguishable_peptides

	def as_protxml
		node = XML::Node.new('peptide')
		node['peptide_sequence']=self.sequence.to_s
		node['charge']=self.charge.to_s
		node['nsp_adjusted_probability']=self.probability.to_s
		node['calc_neutral_pep_mass']=self.theoretical_neutral_mass.to_s
		node
	end

	class << self
		def from_protxml(xmlnode)
			pep=new()
			pep.sequence=xmlnode['peptide_sequence']
			pep.probability=xmlnode['nsp_adjusted_probability'].to_f
			pep.charge=xmlnode['charge'].to_i

			# This deal with the case where mods are on the primary peptide
			#
			mod_info_node = xmlnode.find('protxml:modification_info','protxml:http://regis-web.systemsbiology.net/protXML')

			# The pepXML spec says there can be multiple modification_info's but in practice there never is.
			# We assume either 1 or 0
			if ( mod_info_node.length > 0 )
				throw "Encountered multiple modification_info nodes for a peptide" if mod_info_node.length > 1
				pep.modified_sequence = mod_info_node[0]['modified_peptide']
				mod_nodes = mod_info_node[0].find('protxml:mod_aminoacid_mass','protxml:http://regis-web.systemsbiology.net/protXML')
				# require 'byebug';byebug
				pep.modifications = mod_nodes.collect { |e| PeptideMod.from_protxml(e) }
			end

			# This deals with indistinguishable peptides
			#
			ips = xmlnode.find('protxml:indistinguishable_peptide','protxml:http://regis-web.systemsbiology.net/protXML')
			# require 'byebug';byebug
			pep.indistinguishable_peptides = ips.collect { |e| IndistinguishablePeptide.from_protxml(e) }

			pep
		end

		# <ProteinDetectionHypothesis id="PAG_0_1" dBSequence_ref="JEMP01000193.1_rev_g3500.t1 280755" passThreshold="false">
		# 	<PeptideHypothesis peptideEvidence_ref="PepEv_1">
		# 		<SpectrumIdentificationItemRef spectrumIdentificationItem_ref="SII_1_1"/>
		# 	</PeptideHypothesis>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1002403" name="group representative"/>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1002401" name="leading protein"/>
		# 	<cvParam cvRef="PSI-MS" accession="MS:1001093" name="sequence coverage" value="0.0"/>
		# </ProteinDetectionHypothesis>

		def from_mzid(xmlnode,mzid_doc)
			pep=new()
			pep.sequence=mzid_doc.get_sequence_for_peptide(xmlnode)
			best_psm = mzid_doc.get_best_psm_for_peptide(xmlnode)
			# require 'byebug';byebug if !best_psm
			pep.probability = mzid_doc.get_cvParam(best_psm,"MS:1002466")['value'].to_f
			pep.theoretical_neutral_mass = mzid_doc.get_cvParam(best_psm,"MS:1001117")['value'].to_f
			pep.charge = best_psm.attributes['chargeState'].to_i
			pep.protein_name = mzid_doc.get_dbsequence(xmlnode.parent,xmlnode.parent.attributes['dBSequence_ref']).attributes['accession']


			pep
		end

		def from_sequence(seq,charge=nil)
			pep=new()

			pep.modifications = pep.modifications_from_sequence(seq)
			pep.modified_sequence = seq

			seq = seq.sub(/^n\[[0-9]+?\]/,"")
			pep.sequence = seq.gsub(/[0-9\.\[\]]/,"")
			pep.charge=charge
			pep
		end


		private :new
	end

	def initialize()

	end

	def modifications_from_sequence(seq)

		seq = seq.sub(/^n\[[0-9]+?\]/,"")
		offset = 0
		mods = seq.enum_for(:scan, /([A-Z])\[([0-9\.]+)\]/).map {
			pm = PeptideMod.from_data(Regexp.last_match.begin(0)+1-offset,Regexp.last_match.captures[0],Regexp.last_match.captures[1].to_f)
			offset += Regexp.last_match.captures[1].length+2
			pm
		}

		# if ( seq == "N[115]VMN[115]LTPAETQ[129]QLHAALESQLSPGELAK" )
		# 	require 'byebug';byebug
		# 	puts "hi"
		# end


		mods
	end


	# Expects prot_seq not to contain explicit stop codon (ie * at end)
	# AA coords are 0-based unlike genomic coords which are 1 based
	#
	def coords_in_protein(prot_seq,reverse=false)
		if reverse
			pep_index = prot_seq.reverse.index(self.sequence.reverse)
			raise PeptideNotInProteinError.new("Peptide #{self.sequence} not found in protein #{prot_seq} ") if pep_index.nil?
			pep_start_i = pep_index
		else
			pep_start_i = prot_seq.index(self.sequence)
			raise PeptideNotInProteinError.new("Peptide #{self.sequence} not found in protein #{prot_seq} ") if pep_start_i.nil?			
		end
		pep_end_i = pep_start_i+self.sequence.length
		{:start => pep_start_i,:end => pep_end_i}
	end


	# Returns a list of fragments (hashes with start and end) in GFF style (1 based) genomic coordinates
	#
	# Assumes that cds_coords is inclusive of the entire protein sequence including start-met
	#
	# We assume that gff records conform to the spec
	#
	# http://www.sequenceontology.org/gff3.shtml
	#
	# This part of the spec is crucial
	#
	# - The START and STOP codons are included in the CDS. 
	# - That is, if the locations of the start and stop codons are known, 
	# - the first three base pairs of the CDS should correspond to the start codon
	# - and the last three correspond the stop codon.
	#
	# We also assume that all the cds records provided, actually form part of the protein (ie skipped exons should not be included)
	#
	def to_gff3_records(prot_seq,parent_record,cds_records)

		throw "Expected GFF3 Record but got #{parent_record.class}" unless parent_record.class==Bio::GFF::GFF3::Record
		throw "Expected Array but got #{cds_records.class}" unless cds_records.class==Array

		aa_coords = coords_in_protein(prot_seq,false) # Always use forward protein coordinates

		gff_records_for_coords_in_protein(aa_coords,self.sequence.length,parent_record,cds_records)		
	end

	def mods_to_gff3_records(prot_seq,parent_record,cds_records)

		throw "Expected GFF3 Record but got #{parent_record.class}" unless parent_record.class==Bio::GFF::GFF3::Record
		throw "Expected Array but got #{cds_records.class}" unless cds_records.class==Array

		pep_aa_coords = coords_in_protein(prot_seq,false)

		mod_records = []
		
		unless ( self.modifications.nil? )
			self.modifications.each { |mod|
				prot_position = mod.position+pep_aa_coords[:start]
				mod_aa_coords = {:start => prot_position, :end => prot_position+1}
				mod_records << gff_records_for_coords_in_protein(mod_aa_coords,1,parent_record,cds_records, {:type => "modified_amino_acid_feature", :mod => mod, :modified_sequence => self.modified_sequence})	
			}
		end

		unless ( self.indistinguishable_peptides.nil? )
			self.indistinguishable_peptides.each { |ip|
				unless ( ip.modifications.nil? )
					ip.modifications.each { |mod|
						prot_position = mod.position+pep_aa_coords[:start]-1
						mod_aa_coords = {:start => prot_position, :end => prot_position+1}
						mod_records << gff_records_for_coords_in_protein(mod_aa_coords,1,parent_record,cds_records, {:type => "modified_amino_acid_feature", :mod => mod, :modified_sequence => ip.modified_sequence})	
					}
				end
			} 
		end

		mod_records.flatten
	
	end


	def gff_records_for_coords_in_protein(aa_coords,seqlen,parent_record,cds_records,record_info ={:type => "polypeptide"})
		on_reverse_strand = (parent_record.strand=="-") ? true : false
		ordered_cds_records = on_reverse_strand ? cds_records.sort.reverse : cds_records.sort

		# Initial position is the number of NA's from the start of translation
		#
		pep_nalen = seqlen*3

		i = 0; #Current protein position (in nucleic acids)

		pep_start_i = aa_coords[:start]*3
		pep_end_i = pep_start_i+seqlen*3
		gff_records=[]
		ordered_cds_records.each do |cds_record|

			gff_record = nil
			fragment_len = 0
			if on_reverse_strand

				in_peptide = (i<pep_end_i) && (i>=pep_start_i)
				before_len = [pep_start_i-i,0].max

				if in_peptide
					fragment_end = cds_record.end
					fragment_len = [cds_record.length,pep_end_i-i].min
					fragment_start = fragment_end-fragment_len+1
					gff_record = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record,record_info)
				elsif before_len>0
					fragment_end = cds_record.end - before_len
					fragment_len = [cds_record.length-before_len,pep_end_i-i-before_len].min
					fragment_start = fragment_end - fragment_len + 1
					if fragment_len>0
						gff_record = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record,record_info)
					end
				else
					gff_record=nil
				end				
			else
				in_peptide = (i<pep_end_i) && (i>=pep_start_i)
				before_len = [pep_start_i-i,0].max
				if in_peptide
					fragment_start = cds_record.start
					fragment_len = [cds_record.length,pep_end_i-i].min
					fragment_end = fragment_start+fragment_len-1
					gff_record = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record,record_info)
				elsif before_len>0
					fragment_start = cds_record.start + before_len
					fragment_len = [cds_record.length-before_len,pep_end_i-i-before_len].min
					fragment_end = fragment_start + fragment_len-1
					if fragment_len>0
						gff_record = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record,record_info)
					end
				else
					gff_record = nil
				end

			end
			i+=cds_record.length
			gff_records << gff_record unless gff_record.nil?
		end
		gff_records
	end

	def gff_record_for_peptide_fragment(start_i,end_i,parent_record,record_info)
		cds_id = parent_record.id
		mod_sequence = record_info[:modified_sequence]
		this_id = mod_sequence ? "#{cds_id}.#{mod_sequence}" : "#{cds_id}.#{self.sequence}"
		this_id << ".#{self.charge}" unless self.charge.nil?
		mod = record_info[:mod]
		this_id << ".#{mod.position}.#{mod.mass}" unless mod.nil?
		score = self.probability.nil? ? "." : self.probability.to_s
		record_type = mod.nil? ? record_info[:type] : "#{record_info[:type]}_#{mod.amino_acid}"
		gff_string = "#{parent_record.seqid}\tMSMS\t#{record_type}\t#{start_i}\t#{end_i}\t#{score}\t#{parent_record.strand}\t0\tID=#{this_id};Parent=#{cds_id}"
		Bio::GFF::GFF3::Record.new(gff_string)
	end

end


#             <indistinguishable_peptide peptide_sequence="MEYENTLTAAMK" charge="2" calc_neutral_pep_mass="1416.63">
#             <modification_info modified_peptide="M[147]EYENTLTAAMK"/>
#             </indistinguishable_peptide>
class IndistinguishablePeptide < Peptide
	class << self
		def from_protxml(xmlnode)
			pep=new()
			pep.sequence=xmlnode['peptide_sequence']
			pep.charge=xmlnode['charge'].to_i

			mod_info_node = xmlnode.find('protxml:modification_info','protxml:http://regis-web.systemsbiology.net/protXML')

			if ( mod_info_node.length > 0 )
				throw "Encountered multiple modification_info nodes for an indistinguishable peptide" if mod_info_node.length > 1
				pep.modified_sequence = mod_info_node[0]['modified_peptide']
				mod_nodes = mod_info_node[0].find('protxml:mod_aminoacid_mass','protxml:http://regis-web.systemsbiology.net/protXML')
				if ( mod_nodes.length > 0 )
					pep.modifications = mod_nodes.collect { |e| PeptideMod.from_protxml(e) }
				else
					pep.modifications = pep.modifications_from_sequence(pep.modified_sequence)
				end
			end
			pep
		end
	end
end
