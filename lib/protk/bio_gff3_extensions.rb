require 'bio'

# Extension to GFF3 records to support genomic coordinate mapping tasks

class Bio::GFF::GFF3::Record


# Comparator to allow sorting by start

# Overlap operator to return a new gff by overlapping this one with another

# Function to return our coordinates relative to some other coordinate system (eg a protein)

	def <=>(otherRecord)
		self.start <=> otherRecord.start
	end

	def length
		return self.end-self.start+1
	end

end