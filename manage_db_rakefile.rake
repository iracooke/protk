$LOAD_PATH.unshift("#{File.dirname(__FILE__)}/lib/")
require 'constants'
require 'uri'
require 'digest/md5'
require 'net/ftp'

dbname=ARGV[0]

# Load database spec file
#
$genv=Constants.new()
dbdir="#{$genv.protein_database_root}/#{dbname}"
dbspec=YAML.load_file "#{dbdir}/.protkdb.yaml"

p dbspec

def dirpath_relative_todir(subdir,rootdir)
  
end

def update_ftp_source(source,release_notes)
  rn_uri = URI.parse(release_notes)
  data_uri = URI.parse(source)
  # Both hosts should be the same
  throw "Release notes and data are on different hosts" unless rn_uri.host==data_uri.host


  rn_path="#{$genv.database_downloads}/#{rn_uri.host}/#{rn_uri.path}"
  data_path="#{$genv.database_downloads}/#{rn_uri.host}/#{data_uri.path}"

  # Hash existing release notes data if it exists
  #
  existing_digest=nil
  existing_digest=Digest::MD5.hexdigest(File.read(rn_path))  if  Pathname.new(rn_path).exist? 
  p "Existing data with hash #{existing_digest}" if ( existing_digest!=nil)

  host=rn_uri.host
  Net::FTP.open(host) do |ftp|
    ftp.login
    rn_dir=Pathname.new(rn_uri.path).dirname.to_s
    rn_file=Pathname.new(rn_uri.path).basename.to_s

    login_dir=ftp.getdir()
    ftp.chdir(rn_dir)

    $genv.log("Retrieving release notes for #{source}",:info)

    rn_data=""
    ftp.getbinaryfile(rn_file) { |data| p data ; rn_data << data }

    rn_digest=Digest::MD5.hexdigest(rn_data)

    # Update release notes data
    if ( rn_digest !=nil )
      FileUtils.mkpath(Pathname.new(rn_path).dirname.to_s)
      File.open(rn_path, "w") {|file| file.puts(rn_data) }
    end

    p "Database is up to date" if ( rn_digest==existing_digest)

    if ( rn_digest != existing_digest )

      p "Database out of date. Updating ..."

      p login_dir

      ftp.chdir(login_dir)
      p ftp.getdir()
      p data_uri.path
      ftp.chdir(Pathname.new(data_uri.path).dirname.to_s)

      download_size=ftp.size(Pathname.new(data_uri.path).basename.to_s)
      mod_time=ftp.mtime(Pathname.new(data_uri.path).basename.to_s,true)
      p download_size
      # Make sure our destination dir is available
      #
      FileUtils.mkpath(Pathname.new(data_path).dirname.to_s)

      percent_size=download_size/100
      i=1
      pc_complete=0
      p "Downloading #{Pathname.new(data_uri.path).basename.to_s}"
      ftp.getbinaryfile(Pathname.new(data_uri.path).basename.to_s,data_path,1024) { |data| 
        progress=i*1024
        if ( pc_complete < progress.divmod(percent_size)[0] )
          pc_complete=progress.divmod(percent_size)[0]
          p "Downloading #{Pathname.new(data_uri.path).basename.to_s} #{pc_complete} percent complete"
        end
        i=i+1
      }
    end

  end

  p "Updating #{source}"
end


# List of downloaded and unzipped fasta files to be used as sources
#
unpacked_sources=Array.new()



# Create rake tasks for ftp sources
#
dbspec[:ftp_sources].each do |ftpsource|
  
  release_notes=ftpsource[1]
    
  rn_hash=Digest::MD5.hexdigest(release_notes)

  task rn_hash do 
    update_ftp_source(ftpsource[0],ftpsource[1])
  end

  # Possibly create a task to unzip the file
  #
  data_uri=URI.parse(ftpsource[0])
  data_file_path="#{$genv.database_downloads}/#{data_uri.host}/#{data_uri.path}"
  unpacked_sources << data_file_path unless data_file_path=~/\.gz$/
  if ( data_file_path=~/\.gz$/)
    
    unpacked_data_path=data_file_path.gsub(/\.gz$/,'')
    unpacked_sources<< unpacked_data_path
    file unpacked_data_path do
      sh %{ cd #{Pathname.new(data_file_path).dirname}; gunzip #{Pathname.new(data_file_path).basename}  } 
    end
    
    task rn_hash => unpacked_data_path
    
  end

  task dbname => rn_hash

end

# Create final file by filtering the source
#

# Output database filename
#


# Dynamically create the task
task dbname do 

  unpacked_sources.each do |source|
    p source
  end


end