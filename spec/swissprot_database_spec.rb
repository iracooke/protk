require "protk/swissprot_database"

# We also test for this helper extension here
#
require 'bio'
require 'protk/bio_sptr_extensions'
require 'spec_helper'

describe SwissprotDatabase do

  include_context :tmp_dir_with_fixtures, ["AugustUniprot.dat"]

  let(:spdatabase) { SwissprotDatabase.new("#{@tmp_dir}/AugustUniprot.dat") }

	it "should be possible to initialise an object of class SwissprotDatabase" do
    expect(spdatabase).to be_a SwissprotDatabase
	end
	
	
	it "should be possible to find a single entry for ITAM_HUMAN" do
    itam=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(itam).to be_a Bio::SPTR
	end

	it "should fail gracefully when asked to search for a non-existent protein BLAHBLAH" do
    itam=spdatabase.get_entry_for_name('BLAHBLAH')
    expect(itam).to be_nil
	end
	
	it "should correctly parse the recommended name for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.recname).to eq "Integrin alpha-M"
	end

  it "should be possible to access a key by name" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    key="recname"
    rn=item.send(key)
    expect(rn).to eq("Integrin alpha-M")
  end


	it "should correctly parse the CD Antigen name for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.cd).to eq("CD11b")
	end
	
	it "should correctly parse the Alternate names for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.altnames).to match(/CD11 antigen-like family member B; CR-3 alpha chain; Cell surface glycoprotein MAC-1 subunit alpha; Leukocyte adhesion receptor MO1; Neutrophil adherence receptor/)
	end
	
	it "should correctly parse the SubCellular Location field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    # require 'debugger';debugger
    expect(item.location).to match(/Membrane; Single-pass type I membrane protein/)
	end
	
	it "should correctly parse the Function field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.function).to match(/Integrin alpha-M\/beta-2 is implicated in /)
	end
	
	it "should correctly parse the Similarity field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.similarity).to match(/Belongs to the integrin alpha chain family/)
	end
	
	it "should correctly parse the Tissue Specificity field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.tissues).to match(/Predominantly expressed in monocytes and granulocytes/)
	end

	it "should correctly parse the Disease field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.disease).to match(/lupus erythematosus /)
	end
	
	it "should correctly parse the Domain field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.domain).to match(/The integrin I-domain \(insert\) is a VWFA domain/)
	end
	
	it "should correctly parse the Subunit field for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.subunit).to match(/Heterodimer of an alpha and a beta subunit/)
	end

	it "should correctly obtain a link to the Interaction database entry for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.intact).to eq("P11215") 
  end
  
	it "should correctly obtain a link to the Pride entry for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.pride).to eq("P11215") 
  end

	it "should correctly obtain a link to the Ensembl entry for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.ensembl).to eq("ENST00000287497")
  end
  
  it "should correctly obtain a link to the NextBio entry for ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.nextbio).to eq("14419")
  end
  
  it "should correctly the number of transmembrane regions in ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.num_transmem).to eq("1")	  
  end
  
  it "should correctly the number of signal regions in ITAM_HUMAN" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.signalp).to eq("1")
  end

  it "should correctly retrieve the GO terms" do
    item = spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.go_terms).to be_a Array
    expect(item.go_terms[0]).to eq("GO:0009897")
  end
  it "should correctly retrieve full GO entries" do
    item = spdatabase.get_entry_for_name('ITAM_HUMAN')
    expect(item.go_entries).to be_a Array
    expect(item.go_entries[0][0]).to eq("GO:0009897")
  end  
	
end