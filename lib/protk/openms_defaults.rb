require 'libxml'
include LibXML

class OpenMSDefaults
	attr :featurefinderisotopewavelet
	attr :trf_path
	def initialize
		@featurefinderisotopewavelet="#{File.dirname(__FILE__)}/data/FeatureFinderIsotopeWavelet.ini"
		@trf_path = "#{File.dirname(__FILE__)}/data/ExecutePipeline.trf"
	end
end