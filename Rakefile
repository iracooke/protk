$VERBOSE=nil

require 'fileutils'
require 'yaml'
require 'pathname'

config = YAML.load_file "config.yml"
run_setting=config['run_setting']
config=config[run_setting]

extra_args=ARGV[1]


def gemInstalled(gem_require_name)
  "Testing gem #{gem_require_name}"
  hasit=false
  begin
    require gem_require_name 
    hasit=true
  rescue
  end
  hasit
end
 
desc "Install Lib xml ruby"
task :libxml_ruby_gem do
  if ( !gemInstalled("libxml"))
    install_command="gem install libxml-ruby --no-rdoc --no-ri -- #{extra_args}"
    sh %{ #{install_command} } do |ok,result| 
      if ( !ok)
        puts "Failed to install libxml-ruby gem. If this occurred due to an out of date libxml locat the path to xml2-config then, then run ... \n./setup.sh -- --with-xml2-config=/path/to/xml2-config"
      end
    end
  end
end

desc "Install pure ruby gems"
task :pure_ruby_gems do
  gems={"open4"=>"open4","rest-client"=>"rest_client","bio"=>"bio","logger"=>"logger","net-ftp-list"=>"net/ftp/list"}
  gems.each do |thegem|
    if ( !gemInstalled(thegem[1]))
      sh %{ gem #{thegem[0]} --no-rdoc --no-ri } 
    end
  end
    
end

#
# Function to create links to binaries that are in the users path in the specified install directory
#
def needs_tpp_binary(binary_name,bin_dir)
  result=%x[which #{binary_name}]
  if ( $?.success? ) #Something to link
    path=result.chomp!
    sh %{ /bin/ln -s  #{path} #{bin_dir}/#{binary_name} }
  else
    throw "Unable to find #{binary_name} which is required by protk\n#{binary_name} is distributed as part of the trans proteomic pipeline (TPP).\nTo resolve this error you will need to:\n   - Install the TPP or make sure you already have it installed. Look here http://tools.proteomecenter.org/wiki/index.php?title=Software:TPP for installation instructions\n   - Edit config.yml so that the tpp_bin variable points to the path where the TPP binaries are located."
  end
end

def needs_bin_dir(binary_name,bin_dir,throw_message)
  result=%x[which #{binary_name}]
  if ( $?.success? ) #Something to link
    path=result.chomp!
    origin_dir_path=Pathname.new(path).dirname.to_s
    
    case
    when !Pathname.new(bin_dir).exist?
      sh %{ /bin/ln -s  #{origin_dir_path}/ #{bin_dir} }
    else
      p "WARNING: Can't create link to #{bin_dir}. File exists" 
    end
  else
    p "WARNING: #{throw_message}"
  end
end

def needs_ncbi_binary(binary_name,bin_dir)
  result=%x[which #{binary_name}]
  if ( $?.success? ) #Something to link
    path=result.chomp!
    sh %{ /bin/ln -s  #{path} #{bin_dir}/#{binary_name} }
  else
    throw "Unable to find #{binary_name} which is required by protk\n#{binary_name} is distributed as part of BLAST+.\nTo resolve this error you will need to:\n   - Install the BLAST+ executables or make sure you already have them installed. Look here http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download for installation instructions\n   - Edit config.yml so that the ncbi_bin variable points to the path where the BLAST+ binaries are located."
  end
end

#
# TPP
#

tpp_files=FileList['xinteract','msconvert','tandem','isb_default_input_kscore.xml','Tandem2XML','Mascot2XML']
directory "#{config['tpp_bin']}"

task :tpp => ["#{config['tpp_bin']}"]

# Make a file dependency on each of the tpp binaries
#
tpp_files.each do |fl|
  
  file "#{config['tpp_bin']}/#{fl}" do
    needs_tpp_binary(fl,config['tpp_bin'])
  end
  task :tpp => ["#{config['tpp_bin']}/#{fl}"]
  
end

#
# OMSSA
#

task :omssa => ["#{config['omssa_bin']}/omssacl"]  
file "#{config['omssa_bin']}/omssacl" do
  needs_bin_dir("omssacl",config['omssa_bin'],"Unable to find OMSSA which is required by protk\nTo resolve this error you will need to:\n   - Install OMSSA or make sure you already have it installed. Look here http://pubchem.ncbi.nlm.nih.gov/omssa/download.htm for installation instructions\n   - Edit config.yml so that the omssa_bin variable points to the path where the OMSSA binaries are located.")
end


#
# OpenMS
#
task :openms => ["#{config['openms_bin']}/FeatureFinderCentroided"]  
file "#{config['openms_bin']}/FeatureFinderCentroided" do
  needs_bin_dir("FeatureFinder",config['openms_bin'],"Unable to find OpenMS which is required by protk\nTo resolve this error you will need to:\n   - Install OpenMS or make sure you already have it installed. Look here http://open-ms.sourceforge.net/downloads/ for download and installation instructions\n   - Edit config.yml so that the openms_bin variable points to the path where the OpenMS binaries are located.")
end

#
# NCBI
#
ncbi_files=FileList['makeblastdb']
directory "#{config['ncbi_tools_bin']}"

task :ncbi => ["#{config['ncbi_tools_bin']}"]

ncbi_files.each do |fl|
  
  file "#{config['ncbi_tools_bin']}/#{fl}" do
    needs_ncbi_binary(fl,config['ncbi_tools_bin'])
  end
  task :ncbi => ["#{config['ncbi_tools_bin']}/#{fl}"]
  
end


#
# Make Random
#
file "./bin/make_random" do
  sh %{ gcc -o ./bin/make_random make_random.c -lm } 
end

#
# Default task
#

task :default => ["libxml_ruby_gem","pure_ruby_gems","tpp","omssa","openms","ncbi","./bin/make_random"] 


