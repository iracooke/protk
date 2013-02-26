#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 17/12/2010
#
# Runs an MS/MS search using the X!Tandem search engine
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/search_tool'
require 'protk/xtandem_defaults'
require 'libxml'

include LibXML

# Environment with global constants
#
genv=Constants.new

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new({:msms_search=>true,:background=>true,:glyco=>true,:database=>true,:explicit_output=>true,:over_write=>true,:msms_search_detailed_options=>true})
search_tool.jobid_prefix="x"
search_tool.option_parser.banner = "Run an X!Tandem msms search on a set of mzML input files.\n\nUsage: tandem_search.rb [options] file1.mzML file2.mzML ..."
search_tool.options.output_suffix="_tandem"

tandem_defaults=XTandemDefaults.new.path
search_tool.options.tandem_params=tandem_defaults
search_tool.option_parser.on( '-T', '--tandem-params tandem', 'XTandem parameters to use' ) do |parms| 
  search_tool.options.tandem_params = parms
end

search_tool.options.no_pepxml=false
search_tool.option_parser.on( '-P', '--no-pepxml', 'Dont convert to pepXML after running the search') do
  search_tool.options.no_pepxml=true
end

search_tool.options.keep_params_files=false
search_tool.option_parser.on( '-K', '--keep-params-files', 'Keep X!Tandem parameter files' ) do 
  search_tool.options.keep_params_files = true
end

# In case want pepXML, but still want tandem output also.
search_tool.options.tandem_output=nil
search_tool.option_parser.on( '--tandem-output tandem_output', 'Keep X! Tandem Output') do |tandem_output|
  search_tool.options.tandem_output=tandem_output
end

search_tool.options.thresholds_type = 'isb_kscore'
search_tool.option_parser.on( '--thresholds-type thresholds_type', 'Threshold Type (tandem_default, isb_native, isb_kscore, scaffold, system_default)' ) do |thresholds_type|
  # This options sets up various X! Tandem thresholds. 
  #  - system_default: Don't change any defaults just use
  #      the defaults for this TPP install as is.
  #  - tandem_default: These thresholds are found on the 
  #      tandem api page. http://www.thegpm.org/tandem/api/index.html
  #  - isb_native: These are the defaults found in 
  #      isb_default_input_native.xml distributed with TPP 4.6.
  #  - isb_kscore: These are the defaults found in 
  #      isb_default_input_kscore.xml distributed with TPP 4.6.
  #  - scaffold: These are the defaults recommend by Proteome Software
  #      for use with Scaffold.
  search_tool.options.thresholds_type = thresholds_type
end

search_tool.options.algorithm = "kscore"
search_tool.option_parser.on( '--algorithm algorithm', "Scoring algorithm (kscore or native)" ) do |algorithm|
  search_tool.options.algorithm = algorithm
end

search_tool.options.cleavage_semi = true
search_tool.option_parser.on( '--no-cleavage-semi' ) do
  search_tool.options.cleavage_semi = false
end


search_tool.options.n_terminal_mod_mass=nil
search_tool.option_parser.on('--n-terminal-mod-mass mass') do |mass|
    search_tool.options.n_terminal_mod_mass = mass
end

search_tool.options.c_terminal_mod_mass=nil
search_tool.option_parser.on('--c-terminal-mod-mass mass') do |mass|
    search_tool.options.c_terminal_mod_mass = mass
end

search_tool.options.cleavage_n_terminal_mod_mass=nil
search_tool.option_parser.on('--cleavage-n-terminal-mod-mass mass') do |mass|
    search_tool.options.cleavage_n_terminal_mod_mass = mass
end

search_tool.options.cleavage_c_terminal_mod_mass=nil
search_tool.option_parser.on('--cleavage-c-terminal-mod-mass mass') do |mass|
    search_tool.options.cleavage_c_terminal_mod_mass = mass
end

search_tool.option_parser.parse!


# Set search engine specific parameters on the SearchTool object
#
tandem_bin="#{genv.xtandem}"

throw "Could not find X!Tandem executable" unless FileTest.exists?(tandem_bin)

tandem_params=search_tool.tandem_params

case
when Pathname.new(search_tool.database).exist? # It's an explicitly named db  
  current_db=Pathname.new(search_tool.database).realpath.to_s
else
  current_db=search_tool.current_database :fasta
end


# Parse options from a parameter file (if provided), or from the default parameter file
#
params_parser=XML::Parser.file(tandem_params)
std_params=params_parser.parse

# Parse taxonomy template file
#
taxo_parser=XML::Parser.file(XTandemDefaults.new.taxonomy_path)
taxo_doc=taxo_parser.parse

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
  notes[0].content=value
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
  scoring_notes[0].content="#{genv.tpp_root}/bin/isb_default_input_#{search_tool.algorithm}.xml"

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
  
  var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }
  var_mods=var_mods.collect {|mod| decode_modification_string(mod) }
  fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }
  fix_mods=fix_mods.collect {|mod| decode_modification_string(mod)}
  
  root_bioml_node=std_params.find('/bioml')[0]
  
  mod_id=1
  var_mods.each do |vm|

    mod_type="potential modification mass"
    mod_type = "potential modification motif" if ( vm=~/[\[\]\(\)\{\}\!]/ )      
    mod_id_label = "custom-variable-mod-#{mod_id.to_s}"
    mod_id=mod_id+1
    mnode=XML::Node.new('node')
    mnode["id"]=mod_id_label
    mnode["type"]="input"
    mnode["label"]="residue, #{mod_type}"
    mnode.content=vm
    
    root_bioml_node << mnode
  end
  
  mod_id=1
  fix_mods.each do |fm|
    mod_type="modification mass"
    mod_type = "modification motif" if ( fm=~/[\[\]\(\)\{\}\!]/ )      
    mod_id_label = "custom-fixed-mod-#{mod_id.to_s}"
    mod_id=mod_id+1
    mnode=XML::Node.new('node')
    mnode["id"]=mod_id_label
    mnode["type"]="input"
    mnode["label"]="residue, #{mod_type}"
    mnode.content=fm
    
    root_bioml_node << mnode
  end

  #p root_bioml_node
  std_params
  
end

def generate_taxonomy_doc(taxo_doc,current_db,search_tool)

  taxon_label=taxo_doc.find('/bioml/taxon')
  throw "Exactly one taxon label is required in the taxonomy_template file" unless taxon_label.length==1
  taxon_label[0].attributes['label']=search_tool.database.downcase

  db_file=taxo_doc.find('/bioml/taxon/file')
  throw "Exactly one database file is required in the taxonomy_template file" unless db_file.length==1
  db_file[0].attributes['URL']=current_db

  taxo_doc
end

# Run the search engine on each input file
#
ARGV.each do |filename|

  input_path=Pathname.new(filename.chomp).realpath.to_s
  output_path="#{search_tool.output_base_path(filename.chomp)}.tandem"

  if ( search_tool.explicit_output==nil )
    pepxml_path="#{output_path.match(/(.*)\.tandem$/)[1]}.pep.xml"
  else
    pepxml_path=search_tool.explicit_output
  end
  
  output_exists=false
  if ( !search_tool.no_pepxml && Pathname.new(pepxml_path).exist?)
    output_exists=true
  end
  
  if ( search_tool.no_pepxml && Pathname.new(output_path).exist? )
    output_exists=true
  end
    
  # Only proceed if the output file is not present or we have opted to over-write it
  #
  if ( search_tool.over_write || !output_exists )

    # Create the taxonomy file in the same directory as the params file
    # 
    taxo_path="#{search_tool.input_base_path(filename.chomp)}.taxonomy.xml"
    mod_taxo_doc=generate_taxonomy_doc(taxo_doc,current_db,search_tool)
    mod_taxo_doc.save(taxo_path)

    # Modify the default XML document to contain search specific details and save it so it can be used in the search
    #    
    mod_params=generate_parameter_doc(std_params,output_path,input_path,taxo_path,current_db,search_tool,genv)
    params_path="#{search_tool.input_base_path(filename.chomp)}.tandem.params"
    mod_params.save(params_path)

    # The basic command
    #
    cmd= "#{tandem_bin} #{params_path}"

    # pepXML conversion and repair
    #
    unless search_tool.no_pepxml
      repair_script="#{File.dirname(__FILE__)}/repair_run_summary.rb"
      cmd << "; #{genv.tandem2xml} #{output_path} #{pepxml_path}; #{repair_script} #{pepxml_path}"
      if search_tool.tandem_output 
        cmd << "; cp #{output_path} #{search_tool.tandem_output}"
      else
        cmd << "; rm #{output_path}"
      end
    end

    # Add a cleanup command unless the user wants to keep params files
    #
    unless search_tool.keep_params_files 
      cmd << "; rm #{params_path}; rm #{taxo_path}"
    end

    # In case the user specified background running we need to create a jobscript path
    #
    jobscript_path="#{output_path}.pbs.sh"
 
    # Run the search
    #
    job_params= {:jobid => search_tool.jobid_from_filename(filename)}
    job_params[:queue]="lowmem"
    job_params[:vmem]="900mb"
    code = search_tool.run(cmd,genv,job_params,jobscript_path)
    throw "Command failed with exit code #{code}" unless code==0
  else
    genv.log("Skipping search on existing file #{output_path}",:warn)        
  end

end
