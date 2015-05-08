#!/usr/bin/env ruby
#
#

require 'libxml'
require 'set'

include LibXML
	
MZID_NS_PREFIX="mzidentml"
MZID_NS='http://psidev.info/psi/pi/mzIdentML/1.1'


parser=XML::Parser.file("PeptideShaker.mzid")
@document=parser.parse

def find(node,expression,root=false)
	pp = root ? "//" : "./"
	node.find("#{pp}#{MZID_NS_PREFIX}:#{expression}","#{MZID_NS_PREFIX}:#{MZID_NS}")
end

groups_to_keep=Set.new ["PAG_0","PAG_4"]

groups=@document.find(".//#{MZID_NS_PREFIX}:ProteinAmbiguityGroup","#{MZID_NS_PREFIX}:#{MZID_NS}")

dbsequences_to_keep=Set.new
peptide_evidences_to_keep=Set.new
peptides_to_keep=Set.new
psms_to_keep=Set.new

groups.each do |pg|  
	if groups_to_keep.include? pg.attributes['id']
		prots=find(pg,"ProteinDetectionHypothesis").each do |prot|  
			dbsequences_to_keep << prot.attributes['dBSequence_ref']

			find(prot,"PeptideHypothesis").each do |pepev|
				ev_ref = pepev.attributes['peptideEvidence_ref']
				peptide_evidences_to_keep << ev_ref

# require 'byebug';byebug
				pepev_obj = find(@document.root,"PeptideEvidence[@id=\'#{ev_ref}\']",true)[0]
				peptide_id = pepev_obj.attributes['peptide_ref']
				peptides_to_keep << peptide_id
				dbsequences_to_keep << pepev_obj.attributes['dBSequence_ref']

				find(pepev,"SpectrumIdentificationItemRef").each do |sir|  
					si_ref = sir.attributes['spectrumIdentificationItem_ref']
					psms_to_keep << si_ref
				end

			end

		end
	else
		pg.remove!
	end
end

find(@document.root,"DBSequence",true).each { |dbseq| dbseq.remove! unless dbsequences_to_keep.include? dbseq.attributes['id'] }

find(@document.root,"PeptideEvidence",true).each { |pepev| pepev.remove! unless peptide_evidences_to_keep.include? pepev.attributes['id'] }

find(@document.root,"Peptide",true).each { |pep| pep.remove! unless peptides_to_keep.include? pep.attributes['id'] }

find(@document.root,"SpectrumIdentificationResult",true).each do |sir| 
	has_kept_sii=false
	find(sir,"SpectrumIdentificationItem").each do |sii|  
		if psms_to_keep.include? sii.attributes['id']
			has_kept_sii=true
		end
	end

	sir.remove! unless has_kept_sii
end

@document.save("PeptideShaker_tmp.mzid")

# Then run the tidy command

%x[tidy -xml -i PeptideShaker_tmp.mzid > PeptideShaker_tiny.mzid;rm PeptideShaker_tmp.mzid]