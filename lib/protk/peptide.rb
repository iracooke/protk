require 'libxml'
require 'bio'
require 'protk/bio_gff3_extensions'
require 'protk/error'

include LibXML

class PeptideNotInProteinError < ProtkError
end

class Peptide

	attr_accessor :sequence
	attr_accessor :protein_name
	attr_accessor :charge
	attr_accessor :nsp_adjusted_probability



	class << self
		def from_protxml(xmlnode)
			pep=new()
			pep.sequence=xmlnode['peptide_sequence']
			pep.nsp_adjusted_probability=xmlnode['nsp_adjusted_probability'].to_f
			pep.charge=xmlnode['charge'].to_i
			pep
		end

		def from_sequence(seq,charge=nil)
			pep=new()
			pep.sequence=seq
			pep.charge=charge
			pep
		end
		private :new
	end

	def initialize()

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

		on_reverse_strand = (parent_record.strand=="-") ? true : false
		aa_coords = coords_in_protein(prot_seq,false) # Always use forward protein coordinates

		ordered_cds_records = on_reverse_strand ? cds_records.sort.reverse : cds_records.sort

		# Initial position is the number of NA's from the start of translation
		#
		pep_nalen = self.sequence.length*3

		i = 0; #Current protein position (in nucleic acids)

		pep_start_i = aa_coords[:start]*3
		pep_end_i = pep_start_i+self.sequence.length*3
		fragments=[]
		ordered_cds_records.each do |cds_record|

			fragment = nil
			fragment_len = 0
			if on_reverse_strand

				in_peptide = (i<pep_end_i) && (i>=pep_start_i)
				before_len = [pep_start_i-i,0].max

				if in_peptide
					fragment_end = cds_record.end
					fragment_len = [cds_record.length,pep_end_i-i].min
					fragment_start = fragment_end-fragment_len+1
					fragment = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record)
				elsif before_len>0
					fragment_end = cds_record.end - before_len
					fragment_len = [cds_record.length-before_len,pep_end_i-i-before_len].min
					fragment_start = fragment_end - fragment_len + 1
					if fragment_len>0
						fragment = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record)
					end
				else
					fragment=nil
				end				
			else
				in_peptide = (i<pep_end_i) && (i>=pep_start_i)
				before_len = [pep_start_i-i,0].max
				if in_peptide
					fragment_start = cds_record.start
					fragment_len = [cds_record.length,pep_end_i-i].min
					fragment_end = fragment_start+fragment_len-1
					fragment = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record)
				elsif before_len>0
					fragment_start = cds_record.start + before_len
					fragment_len = [cds_record.length-before_len,pep_end_i-i-before_len].min
					fragment_end = fragment_start + fragment_len-1
					if fragment_len>0
						fragment = gff_record_for_peptide_fragment(fragment_start,fragment_end,cds_record)
					end
				else
					fragment=nil
				end

			end
			i+=cds_record.length
			fragments << fragment unless fragment.nil?
		end
		fragments
	end

	def gff_record_for_peptide_fragment(start_i,end_i,parent_record)
		cds_id = parent_record.id
		this_id = "#{cds_id}.#{self.sequence}"
		this_id << ".#{self.charge}" unless self.charge.nil?
		score = self.nsp_adjusted_probability.nil? ? "." : self.nsp_adjusted_probability.to_s
		gff_string = "#{parent_record.seqid}\tMSMS\tpolypeptide\t#{start_i}\t#{end_i}\t#{score}\t#{parent_record.strand}\t0\tID=#{this_id};Parent=#{cds_id}"
		Bio::GFF::GFF3::Record.new(gff_string)
	end


end