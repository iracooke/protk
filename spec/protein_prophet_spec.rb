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
  let(:tmp_dir) {@tmp_dir}

  describe ["protein_prophet.rb"] do
    it_behaves_like "a protk tool"
  end

  describe ["protein_prophet.rb"] , :dependencies_installed => tpp_installed do
    it_behaves_like "a protk tool with default file output" do
      let(:input_file) { input_files[0]}
      let(:validator) { have_lines_matching(42,"protein_group") }
    end
    it_behaves_like "a protk tool that merges multiple inputs"
    it_behaves_like "a protk tool that supports explicit output"  do
      let(:output_file) { "#{@tmp_dir}/out.prot.xml" }
      let(:input_file) { input_files[0]}
      let(:validator) { have_lines_matching(42,"protein_group") }
    end
  end


  describe ["protein_prophet.rb"] , :dependencies_installed => tpp_installed do

    include_context :galaxy_working_dir_with_fixtures, { 
      "mr176-BSA100fmole_BA3_01_8168.d_tandem_pproph.pep.xml" => "dataset_1.dat"
    }

    let(:input_file) { "#{@galaxy_db_dir}/dataset_1.dat" }
    let(:working_dir) { @galaxy_work_dir }

    it_behaves_like "a protk tool that works with galaxy",:dependencies_installed => tpp_installed do
      let(:extra_args) {"-d #{db_file} "}
      let(:output_file) { "out.prot.xml" }
      let(:validator) { have_lines_matching(1,Regexp.new("#{input_file}")) }
      let(:validator1) { have_lines_matching(0,Regexp.new("galaxy_job_working_dir")) }
    end

  end


end

