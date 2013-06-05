require 'protk/mascot_util'
require 'mascot/dat'
require 'mascot/dat/enzyme'
require 'spec_helper'

describe MascotUtil do
	it "should successfully read the basename of its original input file" do
		MascotUtil.input_basename("#{$this_dir}/data/mascot_results.dat").should=="dataset_600"
	end

	describe "Exported PepXML" do
		before :each do
			@dat = Mascot::DAT.open("#{$this_dir}/data/mascot_results.dat")
		end

		it "can parse the enzyme field" do
			require 'debugger';debugger
			@dat.enzyme.should
		end
	end
end

