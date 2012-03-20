$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")
require 'constants'
require 'uri'
require 'digest/md5'
require 'rubygems'
require 'net/ftp'
require 'net/ftp/list'
require 'bio'
require 'tempfile'
require 'pp'

dbname=ARGV[0]

# Load database spec file
#
$genv=Constants.new()
dbdir="#{$genv.protein_database_root}/#{dbname}"
dbspec=YAML.load_file "#{dbdir}/.protkdb.yaml"

# Output database filename
#
db_filename="#{dbdir}/current.fasta"

#####################
# Utility Functions #
#####################


def check_ftp_release_notes(release_notes)
  rn_uri = URI.parse(release_notes)

  rn_path="#{$genv.database_downloads}/#{rn_uri.host}/#{rn_uri.path}"


  host=rn_uri.host
  Net::FTP.open(host) do |ftp|

    ftp.login
    rn_dir=Pathname.new(rn_uri.path).dirname.to_s
    rn_file=Pathname.new(rn_uri.path).basename.to_s
    ftp.chdir(rn_dir)

    p "Checking release notes"
    
    # Is the last path component a wildcard expression (we only allow *)
    # If so we need to find the file with the most recent modification time
    #
    if ( rn_file =~ /\*/)
      entries=ftp.list(rn_file)
      p entries
      latest_file=nil
      latest_file_mtime=nil
      entries.each do |dir_entry|
        info=Net::FTP::List.parse(dir_entry)
        if ( info.file? )
          latest_file_mtime = info.mtime if ( latest_file_mtime ==nil )
          latest_file = info.basename if ( latest_file_mtime ==nil )
          
          if ( info.mtime <=> latest_file_mtime ) #entry's mtime is later
            latest_file_mtime=info.mtime
            latest_file=info.basename
          end

        end        
      end
        
      throw "No release notes found" if ( latest_file ==nil)

      rn_file=latest_file

      # Adjust the rn_path to be the path of the latest file
      #
      rn_path="#{Pathname.new(rn_path).dirname}/#{latest_file}"

    end

    # Hash existing release notes data if it exists
    #
    existing_digest=nil
    existing_digest=Digest::MD5.hexdigest(File.read(rn_path))  if  Pathname.new(rn_path).exist? 

    rn_data=""
    dl_file=Tempfile.new("rn_file")
    ftp.getbinaryfile(rn_file,dl_file.path) { |data|  rn_data << data }

    rn_digest=Digest::MD5.hexdigest(rn_data)

    throw "No release notes data at #{release_notes}" unless rn_digest!=nil

    # Update release notes data
    case
    when ( existing_digest != rn_digest )
      FileUtils.mkpath(Pathname.new(rn_path).dirname.to_s)
      File.open(rn_path, "w") {|file| file.puts(rn_data) }
    else
      p "Downloaded files are up to date"
    end  
  end
end

def download_ftp_file(ftp,file_name,dest_dir)
  dest_path="#{dest_dir}/#{file_name}"
  
  download_size=ftp.size(file_name)
  mod_time=ftp.mtime(file_name,true)



  percent_size=download_size/100
  i=1
  pc_complete=0
  last_time=Time.new
  p "Downloading #{file_name}"
  ftp.getbinaryfile(file_name,dest_path,1024) { |data| 
    
    progress=i*1024
    if ( pc_complete < progress.divmod(percent_size)[0] && ( Time.new - last_time) > 10 )
      pc_complete=progress.divmod(percent_size)[0]
      p "Downloading #{file_name} #{pc_complete} percent complete"
      last_time=Time.new
    end
    i=i+1
  }
  
end

def download_ftp_source(source)

  data_uri = URI.parse(source)

  data_path="#{$genv.database_downloads}/#{data_uri.host}/#{data_uri.path}"
  # Make sure our destination dir is available
  #
  FileUtils.mkpath(Pathname.new(data_path).dirname.to_s)



  Net::FTP.open(data_uri.host) do |ftp|
    p "Connected to #{data_uri.host}"
    ftp.login
    ftp.chdir(Pathname.new(data_uri.path).dirname.to_s)

    last_path_component=Pathname.new(data_uri.path).basename.to_s
    
    case 
    when last_path_component=~/\*/  # A wildcard match. Need to download them all
      p "Getting directory listing for #{last_path_component}"
      
      matching_items=ftp.list(last_path_component)
      
      PP.pp(matching_items)
      
      matching_items.each do |dir_entry|
        info=Net::FTP::List.parse(dir_entry)
        download_ftp_file(ftp,info.basename,Pathname.new(data_path).dirname)
      end
      
    else # Just one file to download
      download_ftp_file(ftp,last_path_component,Pathname.new(data_path).dirname)
    end

  end

end

  
def archive_fasta_file(filename)
  if ( Pathname.new(filename).exist? )
    mt=File.new(filename).mtime
    timestamp="#{mt.year}_#{mt.month}_#{mt.day}"
    archive_filename="#{filename.gsub(/.fasta$/,'')}_#{timestamp}.fasta"
    p "Moving old database to #{archive_filename}"
    FileUtils.mv(filename,archive_filename)
  end
end

#####################
# Source Files      #
#####################

def file_source(raw_source)
  full_path=raw_source
  full_path = "#{$genv.protein_database_root}/#{raw_source}" unless ( raw_source =~ /^\//) # relative paths should be relative to datbases dir
  throw "File source #{full_path} does not exist" unless Pathname.new(full_path).exist?
  full_path  
end

def db_source(db_source)
  current_release_path = "#{$genv.protein_database_root}/#{db_source}/current.fasta"
  throw "Database source #{db_source} does not exist" unless Pathname.new(current_release_path).exist?
  current_release_path  
end


def ftp_source(ftpsource)
  
  release_notes_url=ftpsource[1]
  data_rn=URI.parse(release_notes_url)
  release_notes_file_path="#{$genv.database_downloads}/#{data_rn.host}/#{data_rn.path}"

  data_uri=URI.parse(ftpsource[0])
  data_file_path="#{$genv.database_downloads}/#{data_uri.host}/#{data_uri.path}"

  task :check_rn do
    check_ftp_release_notes(release_notes_url) 
  end

  file release_notes_file_path => :check_rn

  unpacked_data_path=data_file_path.gsub(/\.gz$/,'')
  
  
  if ( data_file_path=~/\*/) # A wildcard
    unpacked_data_path=data_file_path.gsub(/\*/,"_all_").gsub(/\.gz$/,'')
  end

  file unpacked_data_path => release_notes_file_path do #Unpacking. Includes unzipping and/or concatenating
    download_ftp_source(ftpsource[0])

    case
    when data_file_path=~/\*/ # Multiple files to unzip/concatenate and we don't know what they are yet
      component_files=Dir.glob(data_file_path)
      unzipcmd= "gunzip -f "
      component_files.each do |cf|
        if ( cf =~ /\.gz$/)
          unzipcmd << " #{cf}"
        end
      end
      p "Unzipping ... "
      sh %{ cd #{Pathname.new(data_file_path).dirname}; #{unzipcmd}  }             

      
      catcmd="cat "
      component_files.each {|cf| catcmd << "#{cf.gsub(/\.gz$/,'')} " }
      catcmd << " > #{unpacked_data_path}"
      
      p "Concatenating files #{catcmd}"
      sh %{ cd #{Pathname.new(data_file_path).dirname}; #{catcmd}  }
      
    else # Simple case. A single file
      p "Unzipping #{Pathname.new(data_file_path).basename} ... "
      sh %{ cd #{Pathname.new(data_file_path).dirname}; gunzip -f #{Pathname.new(data_file_path).basename}  }           
    end
  end

  unpacked_data_path
end

source_files=dbspec[:sources].collect do |raw_source|
  sf=""
  case 
  when raw_source.class==Array
    sf=ftp_source(raw_source)
  when raw_source =~ /\.fasta$/
    sf=file_source(raw_source)
  else
    sf=db_source(raw_source)
  end
  sf  
end

#####################
#  Concat & Filter  #
#####################

raw_db_filename = "#{dbdir}/raw.fasta"

file raw_db_filename => source_files do  
  

  archive_fasta_file(raw_db_filename) if dbspec[:archive_old]
  
  output_fh=File.open(raw_db_filename, "w")

  source_filters=dbspec[:include_filters]
  id_regexes=dbspec[:id_regexes]
  source_i=0
  throw "The number of source files #{source_files.length} should equal the number of source filters #{source_filters.length}" unless source_filters.length == source_files.length
  throw "The number of source files #{source_files.length} should equal the number of id regexes #{id_regexes.length}" unless source_filters.length == id_regexes.length

  source_files.each do |source|
    # Open source as Fasta
    #    
    Bio::FlatFile.open(Bio::FastaFormat, source) do |ff|
      p "Reading source file #{source}"

      n_match=0

      filters=source_filters[source_i] #An array of filters for this input file
      id_regex=/#{id_regexes[source_i]}/
      
      ff.each do |entry|
        filters.each do |filter|
          if ( entry.definition =~ /#{filter}/)
            n_match=n_match+1
            idmatch=id_regex.match(entry.definition)
            case 
            when idmatch==nil || idmatch[1]==nil
              p "No match to id regex #{id_regex} for #{entry.definition}. Skipping this entry"              
            else
              new_def="#{idmatch[1]}"
              entry.definition=new_def
              output_fh.puts(entry.to_s)
              p entry.definition.to_s
            end
            break
          end
        end
      end
      p "Warning no match to any filter in #{filters} for source file #{source}" unless n_match > 0
    end
    source_i=source_i+1
  end
  output_fh.close
  
end

#####################
#  Decoys           #
#####################

decoy_db_filename = "#{dbdir}/with_decoys.fasta"
file decoy_db_filename => raw_db_filename do

  archive_fasta_file(decoy_db_filename) if dbspec[:archive_old]


  decoys_filename = "#{dbdir}/decoys_only.fasta"
  decoy_prefix=dbspec[:decoy_prefix]

  # Count entries in the raw input file
  #  
  ff=Bio::FlatFile.open(Bio::FastaFormat, raw_db_filename)
  db_length=0
  ff.each do |entry| 
    db_length=db_length+1 
  end
  
  p "Generating decoy sequences"  
  # Make decoys, concatenate and delete decoy only file
  cmd = "#{$genv.bin}/make_random #{raw_db_filename} #{db_length} #{decoys_filename} #{decoy_prefix}"
  cmd << "; cat #{raw_db_filename} #{decoys_filename} >> #{decoy_db_filename}; rm #{decoys_filename}"
  sh %{ #{cmd} }
end

# Adjust dependencies depending on whether we're making decoys
#
case dbspec[:decoys]
when true
  file db_filename => decoy_db_filename
else
  file db_filename => raw_db_filename
end


###################
# Symlink Current #
###################


# Current database file should symlink to raw or decoy
#
file db_filename do

  # source db filename is either decoy or raw
  #
  case dbspec[:decoys]
  when true
    source_db_filename = decoy_db_filename
  when false
    source_db_filename = raw_db_filename
  end

  p "Current db links to #{source_db_filename}"

  # Symlink to the source file
  #
  File.symlink(source_db_filename,db_filename)

end



###################
# Indexing        #
###################
if dbspec[:make_blast_index] 
  blast_index_files=FileList.new([".phr",".pin",".pog",".psd",".psi",".psq"].collect {|ext| "#{db_filename}#{ext}"  })
  #  task :make_blast_index => blast_index_files  do
  blast_index_files.each do |indfile|
    file indfile => db_filename do
      cmd="cd #{dbdir}; #{$genv.ncbi_tools_bin}/makeblastdb -in #{db_filename} -parse_seqids"
      p "Creating blast index"
      sh %{ #{cmd} }
    end
  end
  
  task dbname => blast_index_files

end

#################
# Root task     #
#################

task dbname => db_filename