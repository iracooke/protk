require File.expand_path('../../decoymaker', __FILE__)

class Randomize
	def self.make_decoys input_path, db_len, output_path, prefix
		Decoymaker.make_decoys input_path.to_s, db_len.to_i,  output_path.to_s, prefix.to_s
	end
end