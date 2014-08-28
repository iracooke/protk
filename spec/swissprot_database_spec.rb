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
	
  let(:itam_human_entry) {
    spdatabase.get_entry_for_name('ITAM_HUMAN')
  }

  describe "ITAM_HUMAN entry" do
    subject { itam_human_entry }
    it { should be_a Bio::SPTR }
    its(:recname) { should eq("Integrin alpha-M")}
    its(:accessions) { should eq(["P11215", "Q4VAK0", "Q4VAK1", "Q4VAK2"])}
    its(:cd) { should eq("CD11b")}
    its(:altnames) { should match(/CD11 antigen-like family member B; CR-3 alpha chain; Cell surface /)}
    its(:location) { should match(/Membrane; Single-pass type I membrane protein/) }
    its(:function) { should match(/Integrin alpha-M\/beta-2 is implicated in /) }
    its(:similarity) { should match(/Belongs to the integrin alpha chain family/)}
    its(:disease) { should match(/lupus erythematosus/) }
    its(:tissues) { should match(/monocytes and granulocytes/)}
    its(:domain) { should match(/I-domain/)}
    its(:subunit) { should match(/alpha and a beta/)}
    its(:intact) { should eq("P11215") } 
    its(:pride) { should eq("P11215") }
    its(:ensembl) { should eq("ENST00000287497")}
    its(:nextbio) { should eq("14419")}
    its(:num_transmem) { should eq("1")}
    its(:signalp) { should eq("1")}
    its(:go_terms) {should include("GO:0009897") }
    its(:go_entries) { should include(["GO:0009897", "C:external side of plasma membrane", "IEA:Ensembl"])}
    its(:ncbi_taxon_id) { should include("9606")}
  end

	it "should fail gracefully when asked to search for a non-existent protein BLAHBLAH" do
    itam=spdatabase.get_entry_for_name('BLAHBLAH')
    expect(itam).to be_nil
	end
	

  it "should be possible to access a key by name" do
    item=spdatabase.get_entry_for_name('ITAM_HUMAN')
    key="recname"
    rn=item.send(key)
    expect(rn).to eq("Integrin alpha-M")
  end
	
end