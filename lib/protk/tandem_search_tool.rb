require 'protk/search_tool'

class String
  def xtandem_modification_motif?
		# 124@[ is not a modification motif, it is a residue (N-term) modification,
		# so when checking if modification is a motif look for paired square brackets.
		ismotif=false
		case self
		when /[\(\)\{\}\!]/,/\[.*\]/
			ismotif=true
		end
		ismotif
  end
end

class TandemSearchTool < SearchTool
	attr :defaults_path
	attr :taxonomy_path
	attr :default_data_path

	attr :supported_xtandem_keys

	def initialize

		super([
			:database,
			:explicit_output,
			:over_write,
			:enzyme,
			:modifications,
			:mass_tolerance_units,
			:mass_tolerance,
			:multi_isotope_search,
			:missed_cleavages,
			:cleavage_semi,
			:methionine_oxidation,
			:glyco,
			:acetyl_nterm,
			:threads
  			])

		@xtandem_keys_with_single_multiplicity = {
			:fragment_tol => "spectrum, fragment monoisotopic mass error",
			:missed_cleavages => "scoring, maximum missed cleavage sites",
			:cleavage_semi => "protein, cleavage semi",
			:precursor_tolu => "spectrum, parent monoisotopic mass error units",
			:multi_isotope_search => "spectrum, parent monoisotopic mass isotope error",
			:fragment_tolu => "spectrum, fragment monoisotopic mass error units",
			:acetyl_nterm => "protein, quick acetyl",
			:output_spectra => "output, spectra",
			:threads => "spectrum, threads"
		}

		@xtandem_keys_for_precursor_tol = {
			:precursor_tol => ["spectrum, parent monoisotopic mass error minus", "spectrum, parent monoisotopic mass error plus"]
		}

		@defaults_path="#{File.dirname(__FILE__)}/data/tandem_params.xml"
		@taxonomy_path="#{File.dirname(__FILE__)}/data/taxonomy_template.xml"
		@default_data_path="#{File.dirname(__FILE__)}/data/"
		
		@option_parser.banner = "Run an X!Tandem msms search on a set of mzML input files.\n\nUsage: tandem_search.rb [options] file1.mzML file2.mzML ..."
		@options.output_suffix="_tandem"

		add_value_option(:tandem_params,"isb_native",['-T', '--tandem-params tandem', 'Either the full path to an xml file containing a complete set of default parameters, or one of the following (isb_native,isb_kscore,gpm). Default is isb_native'])
		add_boolean_option(:keep_params_files,false,['-K', '--keep-params-files', 'Keep X!Tandem parameter files'])
		add_boolean_option(:output_spectra,false,['--output-spectra', 'Include spectra in the output file'])

	end

	private
	# Galaxy changes things like @ to __at__ we need to change it back
	#
	def decode_modification_string(mstring)
  		mstring.gsub!("__at__","@")
  		mstring.gsub!("__oc__","{")
  		mstring.gsub!("__cc__","}")
  		mstring.gsub!("__ob__","[")
  		mstring.gsub!("__cb__","]")
  		mstring
	end

	def set_option(std_params, tandem_key, value)
  		notes = std_params.find("/bioml/note[@type=\"input\" and @label=\"#{tandem_key}\"]")
  		throw "Exactly one parameter named (#{tandem_key}) is required in parameter file" unless notes.length==1
  		notes[0].content=value.to_s
	end

	def append_option(std_params, tandem_key, value)
  		notes = std_params.find("/bioml/note[@type=\"input\" and @label=\"#{tandem_key}\"]")
  		if notes.length == 0
    		node = XML::Node.new('note')
    		node["type"] = "input"
    		node["label"] = tandem_key
    		node.content = value
    		std_params.find('/bioml')[0] << node
  		else
    	throw "Exactly one parameter named (#{tandem_key}) is required in parameter file" unless notes.length==1    
    	notes[0].content = append_string(notes[0].content, value)
  		end
	end

	def tandem_keys_in_params_file(default_params_path)
		params_parser=XML::Parser.file(default_params_path)
		default_params=params_parser.parse
		input_nodes=default_params.find('/bioml/note[@type="input"]')
		defined_keys=[]
		input_nodes.each do |node|
			defined_keys << node.attributes['label']
		end
		defined_keys
	end

	def taxon_from_taxonomy_file(taxo_path)
		taxo_parser=XML::Parser.file(taxo_path)
		taxo_doc=taxo_parser.parse
		taxon_nodes=taxo_doc.find('/bioml/taxon')
		throw "Exactly one taxon entry allowed in taxonomy file but found #{taxon_nodes.length}" unless taxon_nodes.length==1
		taxon_nodes[0].attributes['label']
	end

	def generate_parameter_doc(std_params,output_path,input_path,db_info,taxo_path)

		#
		# The TandemSearchTool class has a special defaults system 
		# Defaults are read from (a) The commandline (b) A defaults file (c) commandline defaults.
		# The ideal priority order is a -> b -> c
		#
		# In order to support this we need to read the defaults file and check options defined there
		# against those defined on the commandline
		#
		# In addition, we support some default parameter files built-in to protk. These are treated the same
		# but are specified if the user provides a keyword rather than a path
		#
		default_params_notes=std_params.find('/bioml/note[@type="input" and @label="list path, default parameters"]')
		throw "Exactly one list path, default parameters note is required in the parameter file" unless default_params_notes.length==1

		is_file=File.exists?(self.tandem_params)
		if is_file
			default_params_notes[0].content="#{self.tandem_params}"			
		else			
			default_params_notes[0].content="#{@default_data_path}tandem_#{self.tandem_params}_defaults.xml"
		end


		keys_in_params_file=tandem_keys_in_params_file(default_params_notes[0].content)
		keys_on_commandline=@options_defined_by_user.keys

		# Set the input and output paths 
		#
		set_option(std_params,"spectrum, path",input_path)
		set_option(std_params,"output, path",output_path)

		# Taxonomy and Database
		#  
		set_option(std_params,"list path, taxonomy information",taxo_path)
		set_option(std_params,"protein, taxon",db_info.name)



		# set_option(std_params, "protein, cleavage semi", self.cleavage_semi ? "yes" : "no")

		# Simple options (unique with a 1:1 mapping to parameters from this tool)
		#
		@xtandem_keys_with_single_multiplicity.each_pair do |commandline_option_key, xtandem_key|  
			if (!keys_in_params_file.include?(xtandem_key) || keys_on_commandline.include?(commandline_option_key))
				opt_val=self.send(commandline_option_key)
				if opt_val.is_a?(TrueClass) || opt_val.is_a?(FalseClass)
					opt_val = opt_val ? "yes" : "no"
				end
				append_option(std_params,xtandem_key,opt_val.to_s) 
			end
		end

		# Precursor mass tolerance is a special case as it requires two xtandem options
		#
		@xtandem_keys_for_precursor_tol.each_pair do |commandline_option_key, xtandem_keys|  
			xtandem_keys.each do |xtandem_key|
				if (!keys_in_params_file.include?(xtandem_key) || keys_on_commandline.include?(commandline_option_key))
					append_option(std_params,xtandem_key,(self.precursor_tol.to_f*0.5).to_s)
				end
			end
		end

		# Per residue Fixed and Variable Modifications
		#
		# These can be added using a variety of methods in xtandem
		#
		# residue, potential modification mass
		# residue, modification mass
		# residue, potential modification motif
		#
		# We support these primarily via the var_mods and fix_mods commandline params
		# Modification masses and/or motifs can be entered via these arguments
		#

		var_mods = self.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }
		var_mods=var_mods.collect {|mod| decode_modification_string(mod) }

		# var_mods allows motif's as well as standard mods. These should be in a separate array
		var_motifs = [].replace(var_mods)
		var_mods.delete_if {|mod| mod.xtandem_modification_motif? }
		var_motifs.keep_if {|mod| mod.xtandem_modification_motif? }

		fix_mods = self.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }
		fix_mods=fix_mods.collect {|mod| decode_modification_string(mod)}

		# We also support the --glyco and --methionineo shortcuts.
		# Add these here. No check is made for duplication
		#
		var_motifs << "0.998@N!{P}[ST]" if self.glyco
		var_mods << "15.994915@M" if self.methionine_oxidation

		append_option(std_params,"residue, modification mass",fix_mods.join(",")) unless fix_mods.length==0
		append_option(std_params,"residue, potential modification mass",var_mods.join(",")) unless var_mods.length==0
		append_option(std_params,"residue, potential modification motif",var_motifs.join(",")) unless var_motifs.length==0

		std_params
  
	end

	public
	def taxonomy_doc(db_info)
		throw "Invalid input db_info must be a FastaDatabase object" unless db_info.class==FastaDatabase
		database_path=db_info.path
		taxon=db_info.name
		# Parse taxonomy template file
		#
		taxo_parser=XML::Parser.file(@taxonomy_path)
		taxo_doc=taxo_parser.parse

		taxon_label=taxo_doc.find('/bioml/taxon')
		throw "Exactly one taxon label is required in the taxonomy_template file" unless taxon_label.length==1
		taxon_label[0].attributes['label']=taxon

		db_file=taxo_doc.find('/bioml/taxon/file')
		throw "Exactly one database file is required in the taxonomy_template file" unless db_file.length==1
		db_file[0].attributes['URL']=database_path

		taxo_doc
	end


	def params_doc(db_info,taxo_path,input_path,output_path)
		params_parser=XML::Parser.file(@defaults_path)
		std_params=params_parser.parse

		
		throw "Invalid input db_info must be a FastaDatabase object" unless db_info.class==FastaDatabase

    	generate_parameter_doc(std_params,output_path,input_path,db_info,taxo_path)
    end



end