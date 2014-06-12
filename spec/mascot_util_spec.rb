require 'protk/mascot_util'
require 'spec_helper'

describe MascotUtil do
	it "should successfully read the basename of its original input file" do
		expect(MascotUtil.input_basename("#{$this_dir}/data/mascot_results.dat")).to eq("dataset_600")
	end
end

