require 'spec_helper'
require 'commandline_shared_examples.rb'

describe "The filter_psms command" do

  include_context :tmp_dir_with_fixtures, [
    "proteogenomics_raw.pep.xml"
  ]

  let(:input_file) { "#{@tmp_dir}/proteogenomics_raw.pep.xml" }

# Input file contains the following psms
# Novel Set
# Vi_1.5019.5019.2 => decoy_novel : No alt
# Vi_1.3537.3537.2 => lcl|scaffold_344_frame_2_orf_2014 : lcl|scaffold_737_frame_1_orf_879

# Known Set
# Vi_1.4608.4608.2 => lcl|scaffold_619_fwd_g1957.t1 : lcl|scaffold_619_frame_2_orf_3522
# Vi_1.3284.3284.2 => decoy_known_rp1927 : None
# Vi_1.3690.3690.2 => lcl|scaffold_840_frame_2_orf_322 : lcl|scaffold_840_fwd_g9750.t1
# Vi_1.3668.3668.2 => lcl|scaffold_709_rev_g2429.t1 : lcl|scaffold_587_frame_1_orf_232 scaffold_587 , fwd

# The last example in the known category deals with the case where an alternative protein might win out over the primary
#

  describe ["filter_psms.rb"] do
    it_behaves_like "a protk tool"

    it_behaves_like "a protk tool that defaults to stdout" do
      let(:extra_args) { "'decoy_novel,frame'"}
      let(:validator) { have_lines_matching(1,"decoy_novel")}
      let(:validator1) { have_lines_matching(0,"decoy_known")}
      let(:validator2) { have_lines_matching(1,"Vi_1.3537.3537.2")}
      let(:validator3) { have_lines_matching(0,"Vi_1.4608.4608.2")}
      let(:validator4) { have_lines_matching(1,"Vi_1.3690.3690.2")}
    end

    it_behaves_like "a protk tool that defaults to stdout" do
      let(:extra_args) { "'decoy_novel,frame' -R"}
      let(:validator) { have_lines_matching(0,"decoy_novel")}
      let(:validator1) { have_lines_matching(1,"decoy_known")}
      let(:validator2) { have_lines_matching(0,"Vi_1.3537.3537.2")}
      let(:validator3) { have_lines_matching(1,"Vi_1.4608.4608.2")}
      let(:validator4) { have_lines_matching(0,"Vi_1.3690.3690.2")}
    end

    # Test the --check-alternatives functionality
    #
    # Known set
    it_behaves_like "a protk tool that defaults to stdout" do
      let(:extra_args) { "'decoy_known,[fr][we][dv]_g' -C"}
      let(:validator) { have_lines_matching(0,"decoy_novel")}
      let(:validator1) { have_lines_matching(1,"decoy_known")}
      let(:validator2) { have_lines_matching(0,"Vi_1.3537.3537.2")}
      let(:validator3) { have_lines_matching(1,"Vi_1.4608.4608.2")}
      let(:validator4) { have_lines_matching(1,"Vi_1.3690.3690.2")}
      let(:validator5) { have_lines_matching(1,"Vi_1.3668.3668.2")}
    end


    # Novel set
    it_behaves_like "a protk tool that defaults to stdout" do
      let(:extra_args) { "'decoy_known,[fr][we][dv]_g' -C -R"}
      let(:validator) { have_lines_matching(1,"decoy_novel")}
      let(:validator1) { have_lines_matching(0,"decoy_known")}
      let(:validator2) { have_lines_matching(1,"Vi_1.3537.3537.2")}
      let(:validator3) { have_lines_matching(0,"Vi_1.4608.4608.2")}
      let(:validator4) { have_lines_matching(0,"Vi_1.3690.3690.2")}
      let(:validator5) { have_lines_matching(0,"Vi_1.3668.3668.2")}
    end

    # Removes lower ranked hits properly
    it_behaves_like "a protk tool that defaults to stdout" do
      let(:extra_args) { "'seq[0-9]+\_m\.[0-9]+' -C"}
      let(:validator) { have_lines_matching(0,"hit_rank=\"2\"")}
      let(:validator1) { have_lines_matching(1,"hit_rank=\"1\"")}
    end


  end

end

