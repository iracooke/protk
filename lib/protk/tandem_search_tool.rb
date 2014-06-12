require 'protk/search_tool'

class TandemSearchTool < SearchTool
	attr :defaults_path
	attr :taxonomy_path
	attr :default_data_path

	attr :supported_xtandem_keys

	def initialize

		super([:glyco,
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
			:carbamidomethyl,
			:methionine_oxidation
  			])

		@xtandem_keys_with_single_multiplicity = {
			:fragment_tol => "spectrum, fragment monoisotopic mass error",
			:missed_cleavages => "scoring, maximum missed cleavage sites",
			:cleavage_semi => "protein, cleavage semi",
			:precursor_tolu => "spectrum, parent monoisotopic mass error units",
			:multi_isotope_search => "spectrum, parent monoisotopic mass isotope error",
			:output_spectra => "output, spectra"
		}

		@xtandem_keys_for_precursor_tol = {
			:precursor_tol => ["spectrum, parent monoisotopic mass error minus", "spectrum, parent monoisotopic mass error plus"]
		}

		@defaults_path="#{File.dirname(__FILE__)}/data/tandem_params.xml"
		@taxonomy_path="#{File.dirname(__FILE__)}/data/taxonomy_template.xml"
		@default_data_path="#{File.dirname(__FILE__)}/data/"
		
		@option_parser.banner = "Run an X!Tandem msms search on a set of mzML input files.\n\nUsage: tandem_search.rb [options] file1.mzML file2.mzML ..."
		@options.output_suffix="_tandem"

		@options.tandem_params="isb_native"
		@option_parser.on( '-T', '--tandem-params tandem', 'Either the full path to an xml file containing a complete set of default parameters, or one of the following (isb_native,gpm_default). Default is isb_native' ) do |parms| 
  			@options.tandem_params = parms
		end

		@options.keep_params_files=false
		@option_parser.on( '-K', '--keep-params-files', 'Keep X!Tandem parameter files' ) do 
  			@options.keep_params_files = true
		end

		@options.n_terminal_mod_mass=nil
		@option_parser.on('--n-terminal-mod-mass mass') do |mass|
  			  @options.n_terminal_mod_mass = mass
		end

		@options.c_terminal_mod_mass=nil
		@option_parser.on('--c-terminal-mod-mass mass') do |mass|
  			  @options.c_terminal_mod_mass = mass
		end

		@options.cleavage_n_terminal_mod_mass=nil
		@option_parser.on('--cleavage-n-terminal-mod-mass mass') do |mass|
  			  @options.cleavage_n_terminal_mod_mass = mass
		end

		@options.cleavage_c_terminal_mod_mass=nil
		@option_parser.on('--cleavage-c-terminal-mod-mass mass') do |mass|
  			  @options.cleavage_c_terminal_mod_mass = mass
		end

		# if contrast angle is set we need to insert two parameters into the XML file ("use contrast angle" and "contrast angle")
		@options.contrast_angle=nil
		@option_parser.on('--contrast-angle angle') do |angle|
  			  @options.contrast_angle = angle
		end

		@options.total_peaks=nil
		@option_parser.on('--total-peaks peaks') do |peaks|
  			  @options.total_peaks = peaks
		end

		# TODO: check default
		@options.use_neutral_loss_window=false
		@option_parser.on('--use-neutral-loss-window') do
  			  @options.use_neutral_loss_window = true
		end


		@options.threads=1
		@option_parser.on('--threads threads') do |threads|
  			  @options.threads = threads
		end

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

	def collapse_keys(std_params, tandem_key)
	    mods=std_params.find('/bioml/note[@type="input" and @label="#{tandem_key}"]')
    	if not mods
      		first_mod = mods[0]
      		rest_mods = mods[1..-1]
      		rest_mods.each{ |node| first_mod.content = append_string(first_mod.content, node.content); node.remove!}
    	end
	end

	def append_string(first, second)
  		if first.empty?
    		second
  		else
    		"#{first},#{second}"
  		end
	end


    def motif?(mod_string)
		# 124@[ is not a modification motif, it is a residue (N-term) modification,
		# so when checking if modification is a motif look for paired square brackets.
		mod_string =~ /[\(\)\{\}\!]/ or mod_string =~ /\[.*\]/
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
		
		# append_option(std_params,"output, spectra",self.output_spectra ? "yes" : "no")


		thresholds_type = self.thresholds_type

		if thresholds_type != "system_default"
			maximum_valid_expectation_value = "0.1"

			if thresholds_type == "scaffold"
			maximum_valid_expectation_value = "1000"
			end 

			minimum_ion_count = "4"
			case thresholds_type 
			when "isb_kscore", "isb_native"
				minimum_ion_count = "1"
			when "scaffold"
				minimum_ion_count = "0"
			end

			minimum_peaks = "15"
			case thresholds_type
			when "isb_native"
				minimum_peaks = "6"
			when "isb_kscore"
				minimum_peaks = "10"
			when "scaffold"
				minimum_peaks = "0"
			end

			minimum_fragement_mz = "150"
			case thresholds_type
			when "isb_native"
				minimum_fragement_mz = "50"
			when "isb_kscore"
				minimum_fragement_mz = "125"
			when "scaffold"
				minimum_fragement_mz = "0"
			end

		    minimum_parent_mh = "500" # tandem and isb_native defaults
    		case thresholds_type
    		when "isb_kscore"
    			minimum_parent_mh = "600"
    		when "scaffold"
    			minimum_parent_mh = "0"
    		end
    
		    use_noise_suppression = "yes"
    		if thresholds_type == "isb_kscore" or thresholds_type == "scaffold"
    			use_noise_suppression = "no"
		    end
    
		    dynamic_range = "100.0"
    		case thresholds_type
    		when "isb_kscore"
    			dynamic_range = "10000.0"
    		when "scaffold"
    			dynamic_range = "1000.0"
    		end

		    set_option(std_params, "spectrum, dynamic range", dynamic_range)
    		set_option(std_params, "spectrum, use noise suppression", use_noise_suppression)
    		set_option(std_params, "spectrum, minimum parent m+h", minimum_parent_mh)
		    set_option(std_params, "spectrum, minimum fragment mz", minimum_fragement_mz)
    		set_option(std_params, "spectrum, minimum peaks", minimum_peaks)
    		set_option(std_params, "scoring, minimum ion count", minimum_ion_count)
    		set_option(std_params, "output, maximum valid expectation value", maximum_valid_expectation_value)
		end

		# Fixed and Variable Modifications
		#
		unless self.carbamidomethyl 
			mods=std_params.find('/bioml/note[@type="input" and @id="carbamidomethyl-fixed"]')
			mods.each{ |node| node.remove!}
		end
	
		unless self.glyco
			mods=std_params.find('/bioml/note[@type="input" and @id="glyco-variable"]')
			mods.each{ |node| node.remove!}  	
		end
	
		unless self.methionine_oxidation
			mods=std_params.find('/bioml/note[@type="input" and @id="methionine-oxidation-variable"]')
			mods.each{ |node| node.remove!} 	     
		end  

		# Merge all remaining id based modification into single modification. 
		# 
		collapse_keys(std_params, "residue, potential modification mass")
		collapse_keys(std_params, "residue, modification mass")

		var_mods = self.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }
		var_mods=var_mods.collect {|mod| decode_modification_string(mod) }
		fix_mods = self.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }
		fix_mods=fix_mods.collect {|mod| decode_modification_string(mod)}
	
		root_bioml_node=std_params.find('/bioml')[0]
	
		mod_id=1
		var_mods.each do |vm|

			mod_type="potential modification mass"
			mod_type = "potential modification motif" if motif?(vm)
			label="residue, #{mod_type}"
			append_option(std_params, label, vm)
		end
	
		mod_id=1
		fix_mods.each do |fm|
			mod_type="modification mass"
			mod_type = "modification motif" if motif?(fm)
			label="residue, #{mod_type}"
			append_option(std_params, label, fm)
		end

		#p root_bioml_node
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