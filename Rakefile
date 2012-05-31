$VERBOSE=nil

require 'fileutils'
require 'yaml'
require 'pathname'
require 'rubygems'

config = YAML.load_file "config.yml"
run_setting=config['run_setting']
config=config[run_setting]

extra_args=ARGV[1]

def gemInstalled?(name)
   Gem::Specification.find_by_name(name)
rescue Gem::LoadError
   false
rescue
   Gem.available?(name)
end

#def gemInstalled?(gem_require_name)
#  "Testing gem #{gem_require_name}"
#  hasit=false
#  begin
#    Gem::Specification.find_by_name(gem_require_name)
#    hasit=true
#  rescue 
#  end
#  hasit
#end
 
desc "Install Lib xml ruby"
task :libxml_ruby_gem do
  if ( !gemInstalled?("libxml-ruby"))
    install_command="gem install libxml-ruby --no-rdoc --no-ri -- #{extra_args}"
    sh %{ #{install_command} } do |ok,result| 
      if ( !ok)
        puts "Failed to install libxml-ruby gem. If this occurred due to an out of date libxml locate the path to xml2-config (you may need to install libxml2 first). Then run ... \n./setup.sh -- --with-xml2-config=/path/to/xml2-config"
      end
    end
  end
end

desc "Install pure ruby gems"
task :pure_ruby_gems do
  gems={"open4"=>"open4","rest-client"=>"rest_client","bio"=>"bio","logger"=>"logger","net-ftp-list"=>"net/ftp/list"}
  gems.each do |thegem|
    if ( !gemInstalled?(thegem[0]))
      sh %{ gem install #{thegem[0]} --no-rdoc --no-ri } 
    end
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

directory "./bin"
task :tpp => "./bin"
task :omssa => "./bin"
task :ncbi => "./bin"
task :openms => "./bin"

#
# TPP
#
task :tpp => ["#{config['tpp_bin']}/xinteract"]  
file "#{config['tpp_bin']}/xinteract" do
  needs_bin_dir("xinteract",config['tpp_bin'],"Unable to find the Trans Proteomic Pipeline (TPP) which is required by protk\nTo resolve this error you will need to:\n   - Install the TPP or make sure you already have it installed. Look here http://tools.proteomecenter.org/wiki/index.php?title=Software:TPP for installation instructions\n   - Edit config.yml so that the tpp_bin variable points to the path where the TPP binaries are located or add this directory to your PATH")
end



#
# OMSSA
#
task :omssa => ["#{config['omssa_bin']}/omssacl"]  
file "#{config['omssa_bin']}/omssacl" do
  needs_bin_dir("omssacl",config['omssa_bin'],"Unable to find OMSSA which is required by protk\nTo resolve this error you will need to:\n   - Install OMSSA or make sure you already have it installed. Look here http://pubchem.ncbi.nlm.nih.gov/omssa/download.htm for installation instructions\n   - Edit config.yml so that the omssa_bin variable points to the path where the OMSSA binaries are located or add this directory to your PATH")
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
task :ncbi => ["#{config['ncbi_tools_bin']}/makeblastdb"]  
file "#{config['ncbi_tools_bin']}/makeblastdb" do
  needs_bin_dir("makeblastdb",config['ncbi_tools_bin'],"Unable to find makeblastdb which is required by protk\n#makeblastdb is distributed as part of BLAST+.\nTo resolve this error you will need to:\n   - Install the BLAST+ executables or make sure you already have them installed. Look here http://blast.ncbi.nlm.nih.gov/Blast.cgi?CMD=Web&PAGE_TYPE=BlastDocs&DOC_TYPE=Download for installation instructions\n   - Edit config.yml so that the ncbi_bin variable points to the path where the BLAST+ binaries are located or add this directory to your PATH")
end



#
# Make Random
#
file "./bin/make_random" do
  sh %{ gcc -o ./bin/make_random make_random.c -lm } 
end

# Make a directory for the Log file
#
log_dir=Pathname.new("#{config['log_file']}").dirname.to_s
directory log_dir

#
# Default task
#

task :default => ["libxml_ruby_gem","pure_ruby_gems",:tpp,"omssa","openms","ncbi","./bin/make_random",log_dir] 


