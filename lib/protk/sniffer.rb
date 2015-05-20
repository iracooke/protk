
class Sniffer

	@sniff_lines = 100

	# Return nil if undetectable
	# Return detected format otherwise
	def self.sniff_format(filepath)
		if self.is_mgf_format(filepath)
			return "mgf"
		elsif self.is_mzml_format(filepath)
			return "mzML"
		end
		return nil
	end


	def self.is_mzml_format(filepath)
		lines = File.foreach(filepath).first(@sniff_lines).join("\n")
		if lines =~ /\<mzML.*http\:\/\/psi\.hupo\.org\/ms\/mzml/
			return true
		end
		return false
	end

	def self.is_mgf_format(filepath)
		lines = File.foreach(filepath).first(@sniff_lines).join("\n")
		if lines =~ /^BEGIN IONS/
			return true
		end
		return false
	end


end