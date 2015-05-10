include LibXML

class PepXMLWriter < Object

	PEPXML_NS_PREFIX="pepxml"
	PEPXML_NS="http://regis-web.systemsbiology.net/pepXML"

	attr :template_doc

	def initialize
		template_path="#{File.dirname(__FILE__)}/data/template_pep.xml"
		template_parser=XML::Parser.file(template_path)
		@template_doc=template_parser.parse
	end

	def append_spectrum_query(query_node)
		@template_doc.root << query_node
	end

	def save(file_path)
		@template_doc.save(file_path,:indent=>true,:encoding => XML::Encoding::UTF_8)
	end

end