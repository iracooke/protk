require 'spec_helper'
require 'protk/peptide'
require 'protk/mzidentml_doc'
require 'rspec/its'




def parse_peptides(protxml_file)
  protxml_parser=XML::Parser.file(protxml_file)
  protxml_doc=protxml_parser.parse
  peptides = protxml_doc.find('.//protxml:peptide','protxml:http://regis-web.systemsbiology.net/protXML')
  peptides
end

describe Peptide do 

	include_context :tmp_dir_with_fixtures, ["test.protXML","PNGaseF.protXML","transdecoder_gff.gff3","augustus_sample.gff","sixframe.gff","braker_min.gff3","PeptideShaker_tiny.mzid"]

	let(:first_peptide) { 
		xmlnodes = parse_peptides("#{@tmp_dir}/test.protXML")
		Peptide.from_protxml(xmlnodes[0])
	}

	describe "first peptide" do
		subject { first_peptide }
		it { should be_a Peptide}
		its(:sequence) {should eq("SGELAVQALDQFATVVEAK")}
		its(:probability) { should eq(0.9981)}
		its(:charge) { should eq(1)}
		its(:modifications) { should eq(nil)}

		it "can map coordinates to protein" do
			coords = first_peptide.coords_in_protein("LSRSGELAVQALDQFATVVEAKLVKHKKGIVN")
			expect(coords[:start]).to eq(3)
			expect(coords[:end]).to eq(22)
		end

		it "can map coordinates to at start of protein" do
			coords = first_peptide.coords_in_protein("SGELAVQALDQFATVVEAKLVKHKKGIVN")
			expect(coords[:start]).to eq(0)
			expect(coords[:end]).to eq(19)
		end

		it "can map coordinates to protein in reverse" do
			coords = first_peptide.coords_in_protein("LSRSGELAVQALDQFATVVEAKLVKHKKGIVN",true)
			expect(coords[:start]).to eq(10)
			expect(coords[:end]).to eq(29)
		end

	end


	let(:modified_peptide) { 
		xmlnodes = parse_peptides("#{@tmp_dir}/test.protXML")
		Peptide.from_protxml(xmlnodes[5])
	}

	# <modification_info modified_peptide="LGEYGFQN[115]AILVR">
	# <mod_aminoacid_mass position="8" mass="115.026930"/>
	# </modification_info>

	describe "modified peptide" do
		subject { modified_peptide }
		it { should be_a Peptide}
		its(:sequence) {should eq("LGEYGFQNAILVR")}
		its(:probability) { should eq(0.9955)}
		its(:charge) { should eq(1)}
		its(:modifications) { should be_a Array}
		its(:modified_sequence) { should eq("LGEYGFQN[115]AILVR")}

		it "should have correct modifications" do
			modifications = modified_peptide.modifications
			expect(modifications.length).to eq(1)
			expect(modifications[0].position).to eq(8)
			expect(modifications[0].mass).to eq(115.026930)
		end
	end


	let(:modified_peptide_with_indistinguishables) { 
		xmlnodes = parse_peptides("#{@tmp_dir}/PNGaseF.protXML")
		Peptide.from_protxml(xmlnodes[9])
	}

#    <peptide peptide_sequence="MEYENTLTAAMK" charge="0" initial_probability="0.9988" nsp_adjusted_probability="0.9996" fpkm_adjusted_probability="0.9996" weight="1.00" group_weight="1.00" is_nondegenerate_evidence="Y" n_enzymatic_termini="2" n_sibling_peptides="5.47" n_sibling_peptides_bin="9" n_instances="7" exp_tot_instances="6.97" is_contributing_evidence="Y">
#             <indistinguishable_peptide peptide_sequence="MEYENTLTAAMK" charge="2" calc_neutral_pep_mass="1400.63">
#             </indistinguishable_peptide>
#             <indistinguishable_peptide peptide_sequence="MEYENTLTAAMK" charge="2" calc_neutral_pep_mass="1416.63">
#             <modification_info modified_peptide="M[147]EYENTLTAAMK"/>
#             </indistinguishable_peptide>
#     </peptide>

	describe "modified peptide with indistinguishables" do
		subject { modified_peptide_with_indistinguishables }
		it { should be_a Peptide }
		its(:sequence) {should eq("MEYENTLTAAMK")}
		its(:probability) { should eq(0.9996)}
		its(:charge) { should eq(0)}
		its(:modifications) { should eq(nil)}
		its(:modified_sequence) { should eq(nil)}

		it "should have indistinguishables" do
			indistinguishables = modified_peptide_with_indistinguishables.indistinguishable_peptides
			expect(indistinguishables.length).to eq(2)
			expect(indistinguishables[0].modifications).to eq(nil)
			expect(indistinguishables[1].charge).to eq(2)
			expect(indistinguishables[1].modified_sequence).to eq("M[147]EYENTLTAAMK")
			expect(indistinguishables[1].modifications.length).to eq(1)
			expect(indistinguishables[1].modifications[0].position).to eq(1)
			expect(indistinguishables[1].modifications[0].mass).to eq(147)
		end
	end


	let(:mzid_doc){
		MzIdentMLDoc.new("#{@tmp_dir}/PeptideShaker_tiny.mzid")
	}

	let(:first_peptide_from_mzid) { 
		xmlnodes = mzid_doc.peptides
		Peptide.from_mzid(xmlnodes[0],mzid_doc)
	}
	
	describe "peptide from mzid" do
		subject { first_peptide_from_mzid }
		it { should be_a Peptide }
		its(:sequence) { should eq("KSPVYKVHFTR")}
		its(:probability) { should eq(0.0)}
		its(:charge) { should eq(1)}
		its(:protein_name) { should eq("JEMP01000193.1_rev_g3500.t1")}
	end

	describe "converting to protxml" do
		subject { first_peptide_from_mzid.as_protxml }
		it { should be_a XML::Node }
		it { should have_attribute_with_value("peptide_sequence","KSPVYKVHFTR")}
		it { should have_attribute_with_value("charge","1")}
		it { should have_attribute_with_value("nsp_adjusted_probability","0.0")}
		it { should have_attribute_with_value("calc_neutral_pep_mass","1360.7615466836999")}
	end


	it "can be initialized just from a sequence" do
		peptide = Peptide.from_sequence("WQCKLVAKPESLSTSPS")
		expect(peptide).to be_a(Peptide)
		expect(peptide.sequence).to eq("WQCKLVAKPESLSTSPS")
		expect(peptide.charge).to eq(nil)

		modified_peptide = Peptide.from_sequence("LGEYGFQN[115]AILVR")
		expect(modified_peptide.sequence).to eq("LGEYGFQNAILVR")
		expect(modified_peptide.modified_sequence).to eq("LGEYGFQN[115]AILVR")

		modifications = modified_peptide.modifications
		expect(modifications.length).to eq(1)
		expect(modifications[0].position).to eq(8)
		expect(modifications[0].mass).to eq(115)
		expect(modifications[0].amino_acid).to eq("N")
	end



	describe "mapping to sixframe gff coordinates" do
		let(:sixframe_gff) {
			gffdb = Bio::GFF::GFF3.new(File.read("#{@tmp_dir}/sixframe.gff"))
			gffdb			
		}
		#
		#scaffold14	sixframe	CDS	1066	1269	.	+	0	ID=scaffold14_frame_1_orf_29
		#
		 let(:orf_positive_strand) {
		 	sixframe_gff.records[2]
		 }
		 let(:protein_orf_positive_strand){
		 	"IILSISAGLPTNTTLPLAKLYTVFCRRNILATTRLDIYILSNYNTLSIGMISIDSQTTIFFHATPAAI"
		 }

		 it "works for a sixframe translation on the positive strand" do
		 	prot_entry = orf_positive_strand
			expect(prot_entry.feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("TPAA")
			peptide_coords = peptide.to_gff3_records(protein_orf_positive_strand,prot_entry,[prot_entry])

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].end).to eq(1269-3)
			expect(peptide_coords[0].start).to eq(1269-3-peptide.sequence.length*3+1)
		 end

		 it "works for a sixframe translation on the positive strand with modification" do
		 	prot_entry = orf_positive_strand
			expect(prot_entry.feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("LPTN[115]TTLP")
			peptide_coords = peptide.to_gff3_records(protein_orf_positive_strand,prot_entry,[prot_entry])

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].end).to eq(1269-3*52)
			expect(peptide_coords[0].start).to eq(1269-3*52-peptide.sequence.length*3+1)

			mod_coords = peptide.mods_to_gff3_records(protein_orf_positive_strand,prot_entry,[prot_entry])
			expect(mod_coords).to be_a(Array)
			expect(mod_coords[0].start).to eq(1066+12*3)
			expect(mod_coords[0].end).to eq(1066+12*3+2)
		 end


		 #
		 #scaffold14	sixframe	CDS	527163	527231	.	-	0	ID=scaffold14_frame_4_orf_32
		 #
		 let(:orf_negative_strand) {
		 	sixframe_gff.records[10]
		 }
		 let(:protein_orf_negative_strand){
		 	"YLQVPTVGLSSTHGRLLACYHEA"
		 }


		 it "works for a sixframe translation on the negative strand" do
		 	prot_entry = orf_negative_strand
			expect(prot_entry.feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("LQVP")
			peptide_coords = peptide.to_gff3_records(protein_orf_negative_strand,prot_entry,[prot_entry])

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].end).to eq(527231-3)
			expect(peptide_coords[0].start).to eq(527231-3-peptide.sequence.length*3+1)
		 end


	end

	describe "mapping to augustus gff coordinates" do
		let(:augustus_gff) { 
			gffdb = Bio::GFF::GFF3.new(File.read("#{@tmp_dir}/augustus_sample.gff"))
			gffdb
		}

		# # Predicted genes for sequence number 1 on both strands
		# # start gene g1
		# scaffold14	AUGUSTUS	gene	2517	3803	.	-	.	ID=g1
		# scaffold14	AUGUSTUS	transcript	2517	3803	0.92	-	.	ID=g1.t1;Parent=g1
		# scaffold14	AUGUSTUS	stop_codon	2517	2519	.	-	0	Parent=g1.t1
		# scaffold14	AUGUSTUS	CDS	2517	3803	0.92	-	0	ID=g1.t1.cds;Parent=g1.t1
		# scaffold14	AUGUSTUS	start_codon	3801	3803	.	-	0	Parent=g1.t1
		# # coding sequence = [atggcagggctagcagcaggcattgttggtgtcgtgtcagctggtaccaaagtcgccatcgtcctttcgcagtatggca
		# # atgaagtgggagcagctggccaagaagcgcgaatgatcgcgtcggaaatccgaggatcatgcacagttctcacgaccctccactcgacattgaaacat
		# # gtccagacatcgccgtactacgcgaattgcgctgaactgatcagcgatatgaccgatgcgagtctggagatgtatacggaaatcatggaggtcgtcga
		# # gggattgtcggcaatgacgagcgacagcaagatgaatttgaggaagcggctgctgtggacctttcaaaagccgaagatcgttatgttgagaacggcac
		# # tggaggcctatagatcgaatttggctcttatgcttggaacgttggatatggctgagaaggcctcgcgaagctacgttgctttgactgaggagattgtg
		# # caggaagatgaaatggactgcgcaaagcttcaagacctacaactggaacaacaaatgtctctgcttaaggttcaagagttggacccggaaagtatcga
		# # gcttccgcctagcccaacgggcgcagggcggggattttgggggtcgtcaaataaagaatctgcatttccagtcgaggagggttatgtcagtgccctga
		# # gagaagagattgcgactctcaagaggagccgaactgtctacctgacagaccccgaaaaggtgcgcgatcgagtagctcgacagagcaatcgtttgtcc
		# # caactcctcgtccaggatcagaggagaatttcgcgaagatggtctcaatccctgccagagagacgtatgagcatgtacagcgacttggcagcagagag
		# # gtcacggtcgcctacgagtacgcctggcagctcatcagcctccccgagcgaatccagcgatgatctatccagcgattatgcccaggtgaacgaaccca
		# # tggttagagacttttatgcttggatgtctgcgcaaactggcgttcagcggagcattgtgcttcgacagctgcaagcgcggtttggtgatgggcgaggg
		# # acaactgtccgcaagcccgtcaacggtgttggaatccatccaggagcaagcgaggacacactatgcgccgatgtctccaagcttgaattggagaagga
		# # tgcagttgcagcagagacctacgagagacaggctgagccagctcctgtggttggagccagtaaggaaaagaagagctcgttcttgaagaggtcaatgg
		# # ggttgaaaagacgaacgccgtcagcgtcgtga]
		# # protein sequence = [MAGLAAGIVGVVSAGTKVAIVLSQYGNEVGAAGQEARMIASEIRGSCTVLTTLHSTLKHVQTSPYYANCAELISDMTD
		# # ASLEMYTEIMEVVEGLSAMTSDSKMNLRKRLLWTFQKPKIVMLRTALEAYRSNLALMLGTLDMAEKASRSYVALTEEIVQEDEMDCAKLQDLQLEQQM
		# # SLLKVQELDPESIELPPSPTGAGRGFWGSSNKESAFPVEEGYVSALREEIATLKRSRTVYLTDPEKVRDRVARQSNRLSQLLVQDQRRISRRWSQSLP
		# # ERRMSMYSDLAAERSRSPTSTPGSSSASPSESSDDLSSDYAQVNEPMVRDFYAWMSAQTGVQRSIVLRQLQARFGDGRGTTVRKPVNGVGIHPGASED
		# # TLCADVSKLELEKDAVAAETYERQAEPAPVVGASKEKKSSFLKRSMGLKRRTPSAS]
		# # end gene g1

		let(:gene_negative_strand_single_cds) {
			augustus_gff.records[(16...22)]
		}

		let(:protein_negative_strand_single_cds){
			"MAGLAAGIVGVVSAGTKVAIVLSQYGNEVGAAGQEARMIASEIRGSCTVLTTLHSTLKHVQTSPYYANCAELISDMTDASLEMYTEIMEVVEGLSAMTSDSKMNLRKRLLWTFQKPKIVMLRTALEAYRSNLALMLGTLDMAEKASRSYVALTEEIVQEDEMDCAKLQDLQLEQQMSLLKVQELDPESIELPPSPTGAGRGFWGSSNKESAFPVEEGYVSALREEIATLKRSRTVYLTDPEKVRDRVARQSNRLSQLLVQDQRRISRRWSQSLPERRMSMYSDLAAERSRSPTSTPGSSSASPSESSDDLSSDYAQVNEPMVRDFYAWMSAQTGVQRSIVLRQLQARFGDGRGTTVRKPVNGVGIHPGASEDTLCADVSKLELEKDAVAAETYERQAEPAPVVGASKEKKSSFLKRSMGLKRRTPSAS"
		}

		it "works for peptide at start with single cds on negative strand" do
			prot_entry = gene_negative_strand_single_cds[1]
			cds_entries = [gene_negative_strand_single_cds[3]]

			expect(prot_entry.feature_type).to eq("transcript")
			expect(cds_entries[0].feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("AGLAAGIVGVVSAGTKVAIVLSQYG")
			peptide_coords = peptide.to_gff3_records(protein_negative_strand_single_cds,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].end).to eq(3800)
			expect(peptide_coords[0].start).to eq(3800-peptide.sequence.length*3+1)
		end


		it "works for peptide at end with single cds on negative strand" do
			prot_entry = gene_negative_strand_single_cds[1]
			cds_entries = [gene_negative_strand_single_cds[3]]

			expect(prot_entry.feature_type).to eq("transcript")
			expect(cds_entries[0].feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("PAPVVGASKEKKSSFLKRSMGLKRRTPSA")
			peptide_coords = peptide.to_gff3_records(protein_negative_strand_single_cds,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].start).to eq(2523)
			expect(peptide_coords[0].end).to eq(2523+peptide.sequence.length*3-1)
		end


		# # start gene g2
		# scaffold14	AUGUSTUS	gene	6798	7541	.	-	.	ID=g2
		# scaffold14	AUGUSTUS	transcript	6798	7541	0.56	-	.	ID=g2.t1;Parent=g2
		# scaffold14	AUGUSTUS	stop_codon	6798	6800	.	-	0	Parent=g2.t1
		# scaffold14	AUGUSTUS	intron	6936	6986	1	-	.	Parent=g2.t1
		# scaffold14	AUGUSTUS	intron	7068	7117	1	-	.	Parent=g2.t1
		# scaffold14	AUGUSTUS	intron	7275	7401	0.63	-	.	Parent=g2.t1
		# scaffold14	AUGUSTUS	CDS	6798	6935	0.97	-	0	ID=g2.t1.cds;Parent=g2.t1
		# scaffold14	AUGUSTUS	CDS	6987	7067	1	-	0	ID=g2.t1.cds;Parent=g2.t1
		# scaffold14	AUGUSTUS	CDS	7118	7274	1	-	1	ID=g2.t1.cds;Parent=g2.t1
		# scaffold14	AUGUSTUS	CDS	7402	7541	0.59	-	0	ID=g2.t1.cds;Parent=g2.t1
		# scaffold14	AUGUSTUS	start_codon	7539	7541	.	-	0	Parent=g2.t1
		# # coding sequence = [atgcctaccagattatccaacacccgcaagcaccgcggtcacgtctctgccggtcacggtcgtgtcggcaagcagtatg
		# # tcacacccctcagcaaccctctcctcgacgttgaacggatcttccaattttcgccattgcaccgcaagcatcccggtggtcgtggtctcgctggtggt
		# # cagcaccaccacaggaccaacatggataaataccatccaggttacttcggaaaggtcggtatgcgatacttccacaagcaaggcaaccacttctggaa
		# # gccaaccatcaacttggacaagctttggtccctcgttcctctcgagcagcgcgaaaagtacatctccaacaagaagtccgacacagctccagttctcg
		# # acctcctctccttcggttactcaaaggtcctcggaaagggtcgtctcccagaaatcccactcgtcgtccgcgcccgatacttctccgcagaagccgaa
		# # aagaagatcaaggaagctggcggagtcgtccagttggtcggttag]
		# # protein sequence = [MPTRLSNTRKHRGHVSAGHGRVGKQYVTPLSNPLLDVERIFQFSPLHRKHPGGRGLAGGQHHHRTNMDKYHPGYFGKV
		# # GMRYFHKQGNHFWKPTINLDKLWSLVPLEQREKYISNKKSDTAPVLDLLSFGYSKVLGKGRLPEIPLVVRARYFSAEAEKKIKEAGGVVQLVG]

		let(:gene_negative_strand_multiple_cds) {
			augustus_gff.records[(43...54)]
		}

		let(:protein_negative_strand_multiple_cds){
			"MPTRLSNTRKHRGHVSAGHGRVGKQYVTPLSNPLLDVERIFQFSPLHRKHPGGRGLAGGQHHHRTNMDKYHPGYFGKVGMRYFHKQGNHFWKPTINLDKLWSLVPLEQREKYISNKKSDTAPVLDLLSFGYSKVLGKGRLPEIPLVVRARYFSAEAEKKIKEAGGVVQLVG"
		}

		it "works for a peptide at start with multiple cds on negative strand 101" do

			prot_entry = gene_negative_strand_multiple_cds[1]
			cds_entries = gene_negative_strand_multiple_cds[(6..9)]

			expect(prot_entry.feature_type).to eq("transcript")
			expect(cds_entries[0].feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("PTRLSNTRKHRGH")
			peptide_coords = peptide.to_gff3_records(protein_negative_strand_multiple_cds,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords.length).to eq(1)
			expect(peptide_coords[0].end).to eq(7538)
			expect(peptide_coords[0].start).to eq(7538-peptide.sequence.length*3+1)

		end

		it "works for a peptide spanning two cds on negative strand" do

			prot_entry = gene_negative_strand_multiple_cds[1]
			cds_entries = gene_negative_strand_multiple_cds[(6..9)]

			expect(prot_entry.feature_type).to eq("transcript")
			expect(cds_entries[0].feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("QFSPLHRKHPGGRGLAGGQHHHRTNM")
			peptide_coords = peptide.to_gff3_records(protein_negative_strand_multiple_cds,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords.length).to eq(2)
			expect(peptide_coords[0].start).to eq(7402)
			expect(peptide_coords[0].end).to eq(7402+2+15-1)
			expect(peptide_coords[1].end).to eq(7274)
			expect(peptide_coords[1].start).to eq(7274-1-(peptide.sequence.length-6)*3+1)
		end




	end

	describe "mapping to transdecoder gff coordinates" do
		let(:transdecoder_gff) { 
			gffdb = Bio::GFF::GFF3.new(File.read("#{@tmp_dir}/transdecoder_gff.gff3"))
			gffdb
		}


		# comp10001_c0_seq1	transdecoder	gene	1	280	.	+	.	ID=comp10001_c0_seq1|g.5608;Name=ORF%20comp10001_c0_seq1%7Cg.5608%20comp10001_c0_seq1%7Cm.5608%20type%3Ainternal%20len%3A94%20%28%2B%29
		# comp10001_c0_seq1	transdecoder	mRNA	1	280	.	+	.	ID=comp10001_c0_seq1|m.5608;Parent=comp10001_c0_seq1|g.5608;Name=ORF%20comp10001_c0_seq1%7Cg.5608%20comp10001_c0_seq1%7Cm.5608%20type%3Ainternal%20len%3A94%20%28%2B%29
		# comp10001_c0_seq1	transdecoder	exon	1	280	.	+	.	ID=comp10001_c0_seq1|m.5608.exon1;Parent=comp10001_c0_seq1|m.5608
		# comp10001_c0_seq1	transdecoder	CDS	2	280	.	+	.	ID=cds.comp10001_c0_seq1|m.5608;Parent=comp10001_c0_seq1|m.5608
		# DMTIQSTTSENAANKAMDLSNGHHNSFVTSNSEWAQISSEKNCMRGIEKLRHDSICSSEDMTQGAIGENGFPSSRDVDGKMFTESSASIKQSK

		let(:gene_records_positive_strand) {
			transdecoder_gff.records[(17...21)]			
		}
		let(:protein_seq_positive_strand) {
			"DMTIQSTTSENAANKAMDLSNGHHNSFVTSNSEWAQISSEKNCMRGIEKLRHDSICSSEDMTQGAIGENGFPSSRDVDGKMFTESSASIKQSK"
		}


		it "works on positive strand" do
			prot_entry = gene_records_positive_strand[1]
			cds_entries = [gene_records_positive_strand[3]]

			expect(prot_entry.feature_type).to eq("mRNA")
			expect(cds_entries[0].feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("STTSENAANKAMDLSNGHHN")
			peptide_coords = peptide.to_gff3_records(protein_seq_positive_strand,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].start).to eq(17)
			expect(peptide_coords[0].end).to eq(17+peptide.sequence.length*3-1)
		end

		let(:gene_records_negative_strand) {
			transdecoder_gff.records[(6...11)]			
		}
		let(:protein_seq_negative_strand) {
			"HGQNVKALHEFISPDYLPQDYYGYLPITDNEEWIQRLLKFDAEFEEESKYGFQELHVANKHLIKDEAMECLVGTYRSLDVE"
		}



		# comp1000154_c0_seq1	transdecoder	gene	1	336	.	-	.	ID=comp1000154_c0_seq1|g.205060;Name=ORF%20comp1000154_c0_seq1%7Cg.205060%20comp1000154_c0_seq1%7Cm.205060%20type%3A5prime_partial%20len%3A82%20%28-%29
		# comp1000154_c0_seq1	transdecoder	mRNA	1	336	.	-	.	ID=comp1000154_c0_seq1|m.205060;Parent=comp1000154_c0_seq1|g.205060;Name=ORF%20comp1000154_c0_seq1%7Cg.205060%20comp1000154_c0_seq1%7Cm.205060%20type%3A5prime_partial%20len%3A82%20%28-%29
		# comp1000154_c0_seq1	transdecoder	exon	1	336	.	-	.	ID=comp1000154_c0_seq1|m.205060.exon1;Parent=comp1000154_c0_seq1|m.205060
		# comp1000154_c0_seq1	transdecoder	CDS	89	334	.	-	.	ID=cds.comp1000154_c0_seq1|m.205060;Parent=comp1000154_c0_seq1|m.205060
		# comp1000154_c0_seq1	transdecoder	three_prime_UTR	1	88	.	-	.	ID=comp1000154_c0_seq1|m.205060.utr3p1;Parent=comp1000154_c0_seq1|m.205060

		it "works for end peptide on negative strand " do
			prot_entry = gene_records_negative_strand[1]

			cds_entries = [gene_records_negative_strand[3]]

			peptide = Peptide.from_sequence("SLDVE")

			peptide_coords = peptide.to_gff3_records(protein_seq_negative_strand,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].start).to eq(92)
			expect(peptide_coords[0].end).to eq(92+peptide.sequence.length*3-1)
		end

		it "works for start peptide on negative strand " do
			prot_entry = gene_records_negative_strand[1]
			cds_entries = [gene_records_negative_strand[3]]

			peptide = Peptide.from_sequence("HGQNVKALHE")

			peptide_coords = peptide.to_gff3_records(protein_seq_negative_strand,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].end).to eq(334)
			expect(peptide_coords[0].start).to eq(334-peptide.sequence.length*3+1)
		end

		it "works for offset start peptide on negative strand " do
			prot_entry = gene_records_negative_strand[1]
			cds_entries = [gene_records_negative_strand[3]]

			peptide = Peptide.from_sequence("GQNVKALHE")

			peptide_coords = peptide.to_gff3_records(protein_seq_negative_strand,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].end).to eq(331)
			expect(peptide_coords[0].start).to eq(331-peptide.sequence.length*3+1)
		end

	end


	describe "mapping to braker gff3 coordinates" do
		let(:braker_gff) {
			gffdb = Bio::GFF::GFF3.new(File.read("#{@tmp_dir}/braker_min.gff3"))
			gffdb
		}


		# start gene g5165
		# JEMP01000008.1	AUGUSTUS	gene	66866	69711	0.91	+	.	ID=g5165
		# JEMP01000008.1	AUGUSTUS	transcript	66866	69711	0.91	+	.	ID=g5165.t1;Parent=g5165
		# JEMP01000008.1	AUGUSTUS	start_codon	66866	66868	.	+	0	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	66912	66973	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	67025	67086	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	67214	67269	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	67436	67484	0.91	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	68307	68357	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	68366	68421	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	68467	68516	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	68560	68903	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	68938	68996	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	69006	69055	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	69077	69126	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	69174	69227	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	intron	69609	69663	1	+	.	Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	66866	66911	1	+	0	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	66974	67024	1	+	2	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	67087	67213	1	+	2	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	67270	67435	0.91	+	1	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	67485	68306	1	+	0	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	68358	68365	1	+	0	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	68422	68466	1	+	1	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	68517	68559	1	+	1	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	68904	68937	1	+	0	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	68997	69005	1	+	2	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	69056	69076	1	+	2	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	69127	69173	1	+	2	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	69228	69608	1	+	0	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	CDS	69664	69711	1	+	0	ID=g5165.t1.cds;Parent=g5165.t1
		# JEMP01000008.1	AUGUSTUS	stop_codon	69709	69711	.	+	0	Parent=g5165.t1
		# protein sequence = [MSYEETYDGAIGIDLGTTYSCVAVYEGNSVEIIANEQGSFTTPSFVSFTAEERLIGEAAKNQAAMNPANTIFDIKRLI
		# GRRFDDETVKKDVESWPFKVVDREGSPFVQVDYLGETKIFSPQEISAMVLGKMKEVAEIKLGKKVEKAVVTVPAYFNDNQRQATKDAGSISGLNVLRI
		# INEPTAAAIAYGLGSGKSEKERNVMIYDLGGGTFDVSLLHIQGGVFTVKATAGDTHLGGQDFDTNLLDHFKKEFSRKTKKDISGDARALRRLRTACER
		# AKRTLSSASSTTVEIDSLFDGEDFTATITRARFEDLNSKAFSGTLQPVEQVLKDSGLEKSKVDEIVLVGGSTRIPRIQKLLSEFFNNKKLEKSINPDE
		# AVAYGAAVQAGILSGKATSAETADLLLLDVVPLSLGVAMEGNIFAPVVPRGNTVPTLKKRTFTTVADQQQTVQFPVFQGERVNCEDNTSLGEFTLAPI
		# PPMRAGEAVLEVVFEVDVNGILKVTATEKTSGRSANITISNSVGKLSSAEIETMVNDAAKFKTSDEAFSKKFESRQQLEAYIARVEEMISDPTSSLKL
		# KQNQRKKIEDSLSDAMAQLEIEDAAAEDLKKKELALKRTVTKAFATR]

		let(:gene_records_positive_strand) {
			braker_gff.records[(1...33)]
		}

		let(:protein_seq_positive_strand) {
			"MSYEETYDGAIGIDLGTTYSCVAVYEGNSVEIIANEQGSFTTPSFVSFTAEERLIGEAAKNQAAMNPANTIFDIKRLIGRRFDDETVKKDV" +
			"ESWPFKVVDREGSPFVQVDYLGETKIFSPQEISAMVLGKMKEVAEIKLGKKVEKAVVTVPAYFNDNQRQATKDAGSISGLNVLRIINEPTAA" +
			"AIAYGLGSGKSEKERNVMIYDLGGGTFDVSLLHIQGGVFTVKATAGDTHLGGQDFDTNLLDHFKKEFSRKTKKDISGDARALRRLRTACERA" +
			"KRTLSSASSTTVEIDSLFDGEDFTATITRARFEDLNSKAFSGTLQPVEQVLKDSGLEKSKVDEIVLVGGSTRIPRIQKLLSEFFNNKKLEKS" +
			"INPDEAVAYGAAVQAGILSGKATSAETADLLLLDVVPLSLGVAMEGNIFAPVVPRGNTVPTLKKRTFTTVADQQQTVQFPVFQGERVNCEDN" +
			"TSLGEFTLAPIPPMRAGEAVLEVVFEVDVNGILKVTATEKTSGRSANITISNSVGKLSSAEIETMVNDAAKFKTSDEAFSKKFESRQQLEAY" +
			"IARVEEMISDPTSSLKLKQNQRKKIEDSLSDAMAQLEIEDAAAEDLKKKELALKRTVTKAFATR"
		}


		it "works on positive strand" do
			prot_entry = gene_records_positive_strand[1]
			cds_entries = gene_records_positive_strand[(16...29)]

			expect(prot_entry.feature_type).to eq("transcript")
			expect(cds_entries.first.feature_type).to eq("CDS")
			expect(cds_entries.last.feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("AFSGTLQPVEQVLK")
			peptide_coords = peptide.to_gff3_records(protein_seq_positive_strand,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].start).to eq(68034)
			expect(peptide_coords[0].end).to eq(68034+peptide.sequence.length*3-1)
		end

		# start gene g5213
		# JEMP01000008.1	AUGUSTUS	gene	205924	207127	1	-	.	ID=g5213
		# JEMP01000008.1	AUGUSTUS	transcript	205924	207127	1	-	.	ID=g5213.t1;Parent=g5213
		# JEMP01000008.1	AUGUSTUS	stop_codon	205924	205926	.	-	0	Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	intron	205957	206101	1	-	.	Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	intron	206234	206291	1	-	.	Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	intron	206970	207019	1	-	.	Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	CDS	205924	205956	1	-	0	ID=g5213.t1.cds;Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	CDS	206102	206233	1	-	0	ID=g5213.t1.cds;Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	CDS	206292	206969	1	-	0	ID=g5213.t1.cds;Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	CDS	207020	207127	1	-	0	ID=g5213.t1.cds;Parent=g5213.t1
		# JEMP01000008.1	AUGUSTUS	start_codon	207125	207127	.	-	0	Parent=g5213.t1
		# protein sequence = [MDAFQNFGKTFSNALMPNIAKTQQLLKEQFGNVNDKTQLPPDYVDLEKRVDALKQVHQKMLQVTSQYTNEAYDYPTNL
		# RESFNDLGRTVSEKVNLLSTANSPSEAAAAMTAPPTAKPQPKTFNHAMARAALTSSHVLTQADHSGTEDPLASALEKFAIAEEKVGEARLAQDAAVQS
		# RFLAGWSTTLNTQLKFATNARKGVENARLNLDATKSKAKAGPGLGFNQRENLGDEEHLTEEARQEIEAKEDEFVAQTEEAEGVMKNVLDTPEPLRNLA
		# ELIAAQIEFHKKAYEILSELGPVVDQLQVEQEASYRKSREGA]
		# end gene g5213

		let(:gene_records_negative_strand) {
			braker_gff.records[(41...52)]
		}

		let(:protein_seq_negative_strand){
			"MDAFQNFGKTFSNALMPNIAKTQQLLKEQFGNVNDKTQLPPDYVDLEKRVDALKQVHQKMLQVTSQYTNEAYDYPTNL" +
			"RESFNDLGRTVSEKVNLLSTANSPSEAAAAMTAPPTAKPQPKTFNHAMARAALTSSHVLTQADHSGTEDPLASALEKFAIAEEKVGEARLAQDAAVQS" +
			"RFLAGWSTTLNTQLKFATNARKGVENARLNLDATKSKAKAGPGLGFNQRENLGDEEHLTEEARQEIEAKEDEFVAQTEEAEGVMKNVLDTPEPLRNLA" +
			"ELIAAQIEFHKKAYEILSELGPVVDQLQVEQEASYRKSREGA"
		}

		it "works on negative strand" do
			prot_entry = gene_records_negative_strand[1]
			cds_entries = gene_records_negative_strand[(6...10)]
			puts gene_records_negative_strand
			puts cds_entries
			# require 'byebug';byebug

			expect(prot_entry.feature_type).to eq("transcript")
			expect(cds_entries.first.feature_type).to eq("CDS")
			expect(cds_entries.last.feature_type).to eq("CDS")

			peptide = Peptide.from_sequence("AALTSSHVLTQADHSGTEDPLASALEK")
			peptide_coords = peptide.to_gff3_records(protein_seq_negative_strand,prot_entry,cds_entries)

			expect(peptide_coords).to be_a(Array)
			expect(peptide_coords[0].start).to eq(206613)
			expect(peptide_coords[0].end).to eq(206613+peptide.sequence.length*3-1)
		end

	end






































end