require 'fileutils'
require 'yaml'
config = YAML.load_file "config.yml"
run_setting=config['run_setting']
config=config[run_setting]

 
desc "Install Lib xml ruby"
task :libxml_ruby_gem do
  sh %{ gem install libxml-ruby --no-rdoc --no-ri }
end

desc "Install pure ruby gems"
task :pure_ruby_gems do
  sh %{ gem install open4 rest-client bio logger spreadsheet net-ftp-list --no-rdoc --no-ri }
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

def needs_omssa_binary(binary_name,bin_dir)
  result=%x[which #{binary_name}]
  if ( $?.success? ) #Something to link
    path=result.chomp!
    sh %{ /bin/ln -s  #{path} #{bin_dir}/#{binary_name} }
  else
    throw "Unable to find #{binary_name} which is required by protk\n#{binary_name} is distributed as part of the OMSSA Search Engine.\nTo resolve this error you will need to:\n   - Install OMSSA or make sure you already have it installed. Look here http://pubchem.ncbi.nlm.nih.gov/omssa/download.htm for installation instructions\n   - Edit config.yml so that the omssa_bin variable points to the path where the OMSSA binaries are located."
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
omssa_files=FileList['omssacl']
directory "#{config['omssa_bin']}"

task :omssa => ["#{config['omssa_bin']}"]

omssa_files.each do |fl|
  
  file "#{config['omssa_bin']}/#{fl}" do
    needs_omssa_binary(fl,config['omssa_bin'])
  end
  task :omssa => ["#{config['omssa_bin']}/#{fl}"]
  
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

task :default => ["libxml_ruby_gem","pure_ruby_gems","tpp","omssa","ncbi","./bin/make_random"] 


