include LibXML

class ProtXMLWriter < Object

	PROTXML_NS_PREFIX="protxml"
	PROTXML_NS="http://regis-web.systemsbiology.net/protXML"

	attr :template_doc
	attr :protein_summary_node

	def initialize
		template_path="#{File.dirname(__FILE__)}/data/template_prot.xml"
		template_parser=XML::Parser.file(template_path)
		@template_doc=template_parser.parse
		@protein_summary_node=@template_doc.root
	end

	def append_protein_group(pg_node)
		# require 'byebug';byebug
		@protein_summary_node << pg_node
	end

	def save(file_path)
		@template_doc.save(file_path,:indent=>true,:encoding => XML::Encoding::UTF_8)
	end

end