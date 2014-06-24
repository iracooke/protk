require 'spec_helper'
require 'commandline_shared_examples.rb'

def tpp_installed
  installed=(%x[which xinteract].length>0)
  installed
end

describe "The protein_prophet command", :broken => false do

  include_context :tmp_dir_with_fixtures, [
    "mr176-BSA100fmole_BA3_01_8168.d_tandem_pproph.pep.xml",
    "mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph.pep.xml"]


  let(:input_files) { ["#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8168.d_tandem_pproph.pep.xml","#{@tmp_dir}/mr176-BSA100fmole_BA3_01_8167.d_tandem_pproph.pep.xml"] }
  let(:output_ext) { ".prot.xml"}
  let(:suffix) { "_protproph" }
  let(:extra_args) { "" }

  describe ["protein_prophet.rb"] do
    it_behaves_like "a protk tool"
  end

  describe ["protein_prophet.rb"] , :dependencies_installed => tpp_installed do
    it_behaves_like "a protk tool with default file output from multiple inputs"
    it_behaves_like "a protk tool that supports explicit output"  do
      let(:output_file) { "#{@tmp_dir}/out.prot.xml" }
      let(:input_file) { input_files[0]}
      let(:validator) { have_lines_matching(42,"protein_group") }
    end
  end

end

