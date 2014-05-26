require 'libxml'
require 'pathname'
include LibXML


class XTandemDefaults
	attr :path
	attr :taxonomy_path
	attr :default_data_path
	def initialize
		@path="#{File.dirname(__FILE__)}/data/tandem_params.xml"
		@taxonomy_path="#{File.dirname(__FILE__)}/data/taxonomy_template.xml"
		@default_data_path="#{File.dirname(__FILE__)}/data/"
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

	def generate_taxonomy_doc(current_db,search_tool)
		# Parse taxonomy template file
		#
		taxo_parser=XML::Parser.file(@taxonomy_path)
		taxo_doc=taxo_parser.parse

		taxon_label=taxo_doc.find('/bioml/taxon')
		throw "Exactly one taxon label is required in the taxonomy_template file" unless taxon_label.length==1
		taxon_label[0].attributes['label']=search_tool.database.downcase

		db_file=taxo_doc.find('/bioml/taxon/file')
		throw "Exactly one database file is required in the taxonomy_template file" unless db_file.length==1
		db_file[0].attributes['URL']=current_db

		taxo_doc
	end


	def generate_parameter_doc(std_params,output_path,input_path,taxo_path,current_db,search_tool,genv)



		set_option(std_params, "protein, cleavage semi", search_tool.cleavage_semi ? "yes" : "no")
		set_option(std_params, "scoring, maximum missed cleavage sites", search_tool.missed_cleavages)

		# Set the input and output paths 
		#
		input_notes=std_params.find('/bioml/note[@type="input" and @label="spectrum, path"]')
		throw "Exactly one spectrum, path note is required in the parameter file" unless input_notes.length==1
		input_notes[0].content=input_path

		output_notes=std_params.find('/bioml/note[@type="input" and @label="output, path"]')
		throw "Exactly one output, path note is required in the parameter file" unless output_notes.length==1
		output_notes[0].content=output_path
  
		# Set the path to the scoring algorithm default params. We use one from ISB
		#
		scoring_notes=std_params.find('/bioml/note[@type="input" and @label="list path, default parameters"]')
		throw "Exactly one list path, default parameters note is required in the parameter file" unless scoring_notes.length==1

		scoring_notes[0].content="#{@default_data_path}isb_default_input_#{search_tool.algorithm}.xml"

		# Taxonomy and Database
		#  
		db_notes=std_params.find('/bioml/note[@type="input" and @label="protein, taxon"]')
		throw "Exactly one protein, taxon note is required in the parameter file" unless db_notes.length==1
		db_notes[0].content=search_tool.database.downcase

		taxo_notes=std_params.find('/bioml/note[@type="input" and @label="list path, taxonomy information"]')
		throw "Exactly one list path, taxonomy information note is required in the parameter file" unless taxo_notes.length==1
		taxo_notes[0].content=taxo_path

		fragment_tol = search_tool.fragment_tol
		
		fmass=std_params.find('/bioml/note[@type="input" and @label="spectrum, fragment monoisotopic mass error"]')
		p fmass
		throw "Exactly one spectrum, fragment monoisotopic mass error note is required in the parameter file" unless fmass.length==1
		fmass[0].content=fragment_tol.to_s
		
		precursor_tol = search_tool.precursor_tol
		ptol_plus=precursor_tol*0.5
		ptol_minus=precursor_tol*0.5

		# Precursor mass matching 
		#
		pmass_minus=std_params.find('/bioml/note[@type="input" and @label="spectrum, parent monoisotopic mass error minus"]')
		throw "Exactly one spectrum, parent monoisotopic mass error minus note is required in the parameter file" unless pmass_minus.length==1
		pmass_minus[0].content=ptol_minus.to_s

		pmass_plus=std_params.find('/bioml/note[@type="input" and @label="spectrum, parent monoisotopic mass error plus"]')
		throw "Exactly one spectrum, parent monoisotopic mass error plus note is required in the parameter file" unless pmass_plus.length==1
		pmass_plus[0].content=ptol_plus.to_s

		pmass_err_units=std_params.find('/bioml/note[@type="input" and @label="spectrum, parent monoisotopic mass error units"]')
		throw "Exactly one spectrum, parent monoisotopic mass error units note is required in the parameter file. Got #{pmass_err_units.length}" unless pmass_err_units.length==1
		
		
		pmass_err_units[0].content=search_tool.precursor_tolu

		if search_tool.strict_monoisotopic_mass
			isotopic_error=std_params.find('/bioml/note[@type="input" and @label="spectrum, parent monoisotopic mass isotope error"]')
			throw "Exactly one spectrum, parent monoisotopic mass isotope error is required in the parameter file" unless isotopic_error.length==1
			isotopic_error[0].content="no"
		end
		
		if search_tool.tandem_output
  			# If one is interested in the tandem output (e.g. for consumption by Scaffold)
  			# want to store additional information.
  			set_option(std_params, "output, spectra", "yes")
		end

		thresholds_type = search_tool.thresholds_type

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
		unless search_tool.carbamidomethyl 
			mods=std_params.find('/bioml/note[@type="input" and @id="carbamidomethyl-fixed"]')
			mods.each{ |node| node.remove!}
		end
	
		unless search_tool.glyco
			mods=std_params.find('/bioml/note[@type="input" and @id="glyco-variable"]')
			mods.each{ |node| node.remove!}  	
		end
	
		unless search_tool.methionine_oxidation
			mods=std_params.find('/bioml/note[@type="input" and @id="methionine-oxidation-variable"]')
			mods.each{ |node| node.remove!} 	     
		end  

		# Merge all remaining id based modification into single modification. 
		collapse_keys(std_params, "residue, potential modification mass")
		collapse_keys(std_params, "residue, modification mass")

		var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }
		var_mods=var_mods.collect {|mod| decode_modification_string(mod) }
		fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }
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
	def generate_params(params_path,taxo_path,input_path,output_path,search_tool,genv)
	    # Create the taxonomy file in the same directory as the params file
    	#

    	case
		when Pathname.new(search_tool.database).exist? # It's an explicitly named db  
			current_db=Pathname.new(search_tool.database).realpath.to_s
		else
			current_db=search_tool.current_database :fasta
		end


		mod_taxo_doc=generate_taxonomy_doc(current_db,search_tool)
		mod_taxo_doc.save(taxo_path)


		# Parse options from a parameter file (if provided), or from the default parameter file
		#
		params_parser=XML::Parser.file(search_tool.tandem_params)
		std_params=params_parser.parse

	    # Modify the default XML document to contain search specific details and save it so it can be used in the search
    	#    
    	mod_params=generate_parameter_doc(std_params,output_path,input_path,taxo_path,current_db,search_tool,genv)
    	mod_params.save(params_path)
    	return [params_path,taxo_path]
    end



end