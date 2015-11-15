include LibXML

class ProtXMLWriter < Object

	PROTXML_NS_PREFIX="protxml"
	PROTXML_NS="http://regis-web.systemsbiology.net/protXML"

	attr :template_doc
	attr :protein_summary_node
	XML.indent_tree_output = true

	def initialize
		template_path="#{File.dirname(__FILE__)}/data/template_prot.xml"
		template_parser=XML::Parser.file(template_path)#,:options => XML::Parser::Options::NOBLANKS)
		@template_doc=template_parser.parse
		@protein_summary_node=@template_doc.root
		# @protein_summary_node.space_preserve=true
		@protein_summary_node.content=""
		puts @template_doc

	end

	def append_header(header_node)
		# require 'byebug';byebug
		@protein_summary_node << header_node.as_protxml
	end

	def append_protein_group(pg_node)
		# require 'byebug';byebug
		@protein_summary_node << pg_node
	end

	def append_dataset_derivation()
		ddnode = XML::Node.new('dataset_derivation')
		ddnode["generation_no"]="0"
		@protein_summary_node << ddnode
	end

	def save(file_path)
		# puts XML.indent_tree_output
		# puts "|#{XML.default_tree_indent_string}|"
		XML.indent_tree_output = true
		# puts @template_doc.to_s
		@template_doc.save(file_path,:indent=>true,:encoding => XML::Encoding::UTF_8)
	end

end