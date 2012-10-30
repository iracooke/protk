require "protk/swissprot_database"

# We also test for this helper extension here
#
require 'bio'
require 'protk/bio_sptr_extensions'
require 'spec_helper'

# All these tests are broken because they require that a swissprot database is actually installed

describe SwissprotDatabase, :broken=>true do

  before do
	end

  it "should be possible to access a key by name" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
#    p item
    key="recname"
    item.send(key).should=="Integrin alpha-M"
  end

	it "should be possible to initialise an object of class SwissprotDatabase" do
    SwissprotDatabase.new.class.should == SwissprotDatabase
	end
	
	
	it "should be possible to find a single entry for ITAM_HUMAN" do
    itam=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    itam.class.should==Bio::SPTR
	end

#	it "should fail gracefully when asked to search for a non-existent protein BLAHBLAH" do
#    itam=SwissprotDatabase.new.get_entry_for_name('BLAHBLAH')
#    itam.should==nil
#	end
	
	it "should correctly parse the recommended name for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.recname.should=="Integrin alpha-M"
	end


	it "should correctly parse the CD Antigen name for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.cd.should=="CD11b"
	end
	
	it "should correctly parse the Alternate names for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.altnames.should=="CD11 antigen-like family member B; CR-3 alpha chain; Cell surface glycoprotein MAC-1 subunit alpha; Leukocyte adhesion receptor MO1; Neutrophil adherence receptor"
	end
	
	it "should correctly parse the SubCellular Location field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.location.should=="Membrane; Single-pass type I membrane protein."
	end
	
	it "should correctly parse the Function field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.function.should=="Integrin alpha-M/beta-2 is implicated in various adhesive interactions of monocytes, macrophages and granulocytes as well as in mediating the uptake of complement-coated particles. It is identical with CR-3, the receptor for the iC3b fragment of the third complement component. It probably recognizes the R-G-D peptide in C3b. Integrin alpha-M/beta-2 is also a receptor for fibrinogen, factor X and ICAM1. It recognizes P1 and P2 peptides of fibrinogen gamma chain."
	end
	
	it "should correctly parse the Similarity field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.similarity.should=="Belongs to the integrin alpha chain family.Contains 7 FG-GAP repeats.Contains 1 VWFA domain."
	end
	
	it "should correctly parse the Tissue Specificity field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.tissues.should=="Predominantly expressed in monocytes and granulocytes."
	end

	it "should correctly parse the Disease field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.disease.should=="Genetic variations in ITGAM has been associated with susceptibility to systemic lupus erythematosus type 6 (SLEB6) [MIM:609939]. Systemic lupus erythematosus (SLE) is a chronic, inflammatory and often febrile multisystemic disorder of connective tissue. It affects principally the skin, joints, kidneys and serosal membranes. It is thought to represent a failure of the regulatory mechanisms of the autoimmune system."
	end
	
	it "should correctly parse the Domain field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.domain.should=="The integrin I-domain (insert) is a VWFA domain. Integrins with I-domains do not undergo protease cleavage."
	end
	
	it "should correctly parse the Subunit field for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.subunit.should=="Heterodimer of an alpha and a beta subunit. Alpha-M associates with beta-2. Interacts with JAM3."
	end
	
	it "should correctly obtain a link to the IPI entry for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.ipi.should=="IPI00217987"	  
  end

	it "should correctly obtain a link to the Interaction database entry for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.intact.should=="P11215"	  
  end
  
	it "should correctly obtain a link to the Pride entry for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.pride.should=="P11215"	  
  end

	it "should correctly obtain a link to the Ensembl entry for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.ensembl.should=="ENST00000287497"	  
  end
  
  it "should correctly obtain a link to the NextBio entry for ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.nextbio.should=="14419"	  
  end
  
  it "should correctly the number of transmembrane regions in ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.num_transmem.should=="1"	  
  end
  
  it "should correctly the number of signal regions in ITAM_HUMAN" do
    item=SwissprotDatabase.new.get_entry_for_name('ITAM_HUMAN')
    item.signalp.should=="1"	  
  end
  
	
end