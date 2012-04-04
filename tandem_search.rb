#
# This file is part of protk
# Created by Ira Cooke 17/12/2010
#
# Runs an MS/MS search using the X!Tandem search engine
#
#!/bin/sh
if [ -z "$PROTK_RUBY_PATH" ] ; then
  PROTK_RUBY_PATH=`which ruby`
fi

eval 'exec "$PROTK_RUBY_PATH" $PROTK_RUBY_FLAGS -rubygems -x -S $0 ${1+"$@"}'
echo "The 'exec \"$PROTK_RUBY_PATH\" -x -S ...' failed!" >&2
exit 1
#! ruby
#

$VERBOSE=nil

$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib")


require 'constants'
require 'command_runner'
require 'search_tool'
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

tandem_defaults="#{File.dirname(__FILE__)}/params/tandem_params.xml"

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

search_tool.option_parser.parse!


# Set search engine specific parameters on the SearchTool object
#
tandem_bin="#{genv.tpp_bin}/tandem.exe"

if ( !FileTest.exists?(tandem_bin))
  tandem_bin="#{genv.tpp_bin}/tandem"
  throw "Could not find X!Tandem executable" unless FileTest.exists?(tandem_bin)
end

tandem_params=search_tool.tandem_params
current_db=search_tool.current_database :fasta



# Parse options from a parameter file (if provided), or from the default parameter file
#
params_parser=XML::Parser.file(tandem_params)
std_params=params_parser.parse

# Parse taxonomy template file
#
taxo_parser=XML::Parser.file("#{File.dirname(__FILE__)}/params/taxonomy_template.xml")
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

def generate_parameter_doc(std_params,output_path,input_path,taxo_path,current_db,search_tool,genv)
  
  
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
  scoring_notes[0].content="#{genv.tpp_bin}/isb_default_input_kscore.xml"

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
      cmd << "; #{genv.tpp_bin}/Tandem2XML #{output_path} #{pepxml_path}; #{repair_script} #{pepxml_path}; rm #{output_path}"
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