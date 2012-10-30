require 'libxml'
include LibXML

class XTandemDefaults
	attr :path
	attr :taxonomy_path
	def initialize
		@path="#{File.dirname(__FILE__)}/data/tandem_params.xml"
		@taxonomy_path="#{File.dirname(__FILE__)}/data/taxonomy_template.xml"
	end


end