require 'protk/protk'

class Randomize
	def self.make_decoys input_path, db_len, output_path, prefix
		Protk.make_decoys input_path.to_s, db_len.to_i,  output_path.to_s, prefix.to_s
	end
end