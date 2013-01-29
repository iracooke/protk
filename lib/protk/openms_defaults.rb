require 'libxml'
include LibXML

class OpenMSDefaults
	attr :featurefinderisotopewavelet
	def initialize
		@featurefinderisotopewavelet="#{File.dirname(__FILE__)}/data/FeatureFinderIsotopeWavelet.ini"
	end
end