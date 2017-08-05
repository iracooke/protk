require 'libxml'
require 'bio'

include LibXML

class PeptideMod

	# Fully Modified Sequence
	attr_accessor :position
	attr_accessor :amino_acid
	attr_accessor :mass

	class << self

		# <modification_info modified_peptide="GFGFVTYSC[160]VEEVDAAMC[160]ARPHK">
		# <mod_aminoacid_mass position="9" mass="160.030600"/>
		# <mod_aminoacid_mass position="18" mass="160.030600"/>
		# </modification_info>

		def from_protxml(xmlnode)
			pepmod = new()
			pepmod.position=xmlnode['position'].to_i
			pepmod.mass=xmlnode['mass'].to_f
			pepmod
		end

		def from_data(position,amino_acid,mass)
			pepmod = new()
			pepmod.position = position
			pepmod.amino_acid = amino_acid
			pepmod.mass = mass
			pepmod
		end

		private :new
	end

	def initialize()

	end

end