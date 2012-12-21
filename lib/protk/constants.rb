# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Initialises global constants. 
# All tools should source this file.
#
require 'yaml'
require 'logger'
require 'pathname'
require 'ftools'

class Constants

  # A Hash holding all the constants
  #
  @env
  
  # These are logger attributes with thresholds as indicated
  #  DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
  #Debug (development mode) or Info (production)
  #
  @stdout_logger 
  
  #Warn
  #
  @file_logger 



  attr :info_level
  attr :protk_dir

  # Provides direct access to constants through methods of the same name
  # This will be used for all constants other than paths
  #
  def method_missing(method)
    @env[method.to_s]
  end

  # Some constants are paths. They need to be translated into real paths before being returned
  #
  
  def bin
    return "#{@protk_dir}/bin"
  end
  
  def tpp_root
    path=@env['tpp_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['tpp_root']}"
    end
  end

  def xinteract
    return "#{self.tpp_root}/bin/xinteract"
  end

  def xtandem    
    return "#{self.tpp_root}/bin/tandem"
  end

  def tandem2xml
    return "#{self.tpp_root}/bin/Tandem2XML"
  end
  
  def interprophetparser
    return "#{self.tpp_root}/bin/InterProphetParser"
  end

  def proteinprophet
    return "#{self.tpp_root}/bin/ProteinProphet"
  end

  def asapratiopeptideparser
    return "#{self.tpp_root}/bin/ASAPRatioPeptideParser"
  end

  def asapratioproteinparser
    return "#{self.tpp_root}/bin/ASAPRatioProteinRatioParser"
  end

  def asaprationpvalueparser
    return "#{self.tpp_root}/bin/ASAPRatioPvalueParser"
  end

  def librapeptideparser
    return "#{self.tpp_root}/bin/LibraPeptideParser"
  end

  def libraproteinratioparser
    return "#{self.tpp_root}/bin/LibraProteinRatioParser"
  end

  def xpresspeptideparser
    return "#{self.tpp_root}/bin/XPressPeptideParser"
  end

  def xpressproteinratioparser
    return "#{self.tpp_root}/bin/XPressProteinRatioParser"
  end

  def mascot2xml
    return "#{self.tpp_root}/bin/Mascot2XML"
  end
  
  def omssa_root
    path=@env['omssa_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['omssa_root']}"
    end
  end

  def omssacl
    return "#{self.omssa_root}/omssacl"
  end

  def omssa2pepxml
    return "#{self.omssa_root}/omssa2pepXML"
  end
  
  def msgfplus_root
    path=@env['msgfplus_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['msgfplus_root']}"
    end
  end

  def msgfplusjar
    return "#{self.msgfplus_root}/MSGFPlus.jar"
  end

  def pwiz_root
    path=@env['pwiz_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['pwiz_root']}"
    end    
  end

  def idconvert
    return "#{self.pwiz_root}/idconvert"
  end

  def msconvert
    return "#{self.pwiz_root}/msconvert"
  end

  def openms_root
    path=@env['openms_root']
    if ( path =~ /^\//)
      return path 
    else
      return "#{@protk_dir}/#{@env['openms_root']}"
    end
  end

  def featurefinderisotopewavelet
    return "#{self.openms_root}/bin/FeatureFinderIsotopeWavelet"
  end

  def protein_database_root
    path=@env['protein_database_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['protein_database_root']}"
    end
  end
  
  def database_downloads
    return "#{self.protein_database_root}/downloads"
  end
  
  def blast_root
    path=@env['blast_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['blast_root']}"   
    end 
  end

  def makeblastdb
    return "#{self.blast_root}/bin/makeblastdb"
  end
  
  def log_file
    path=@env['log_file']
    if ( path =~ /^\// )
      return path
    else
      return "#{@protk_dir}/#{@env['log_file']}"
    end
  end


  # Read the global constants file and initialize our class @env variable
  # Initialize loggers
  #
  def initialize 

    @protk_dir="#{Dir.home}/.protk"


    default_config_yml = YAML.load_file "#{File.dirname(__FILE__)}/data/default_config.yml"
    throw "Unable to read the config file at #{File.dirname(__FILE__)}/data/default_config.yml" unless default_config_yml!=nil

    @env=default_config_yml
    throw "No data found in config file" unless @env!=nil
    @info_level=default_config_yml['message_level']

    
  end


  def initialize_loggers
    log_dir = Pathname.new(self.log_file).dirname
    log_dir.mkpath unless log_dir.exist?

    @stdout_logger=Logger.new(STDOUT)
    @file_logger=Logger.new(self.log_file)

    throw "Unable to create file logger at path #{self.log_file}" unless @file_logger!=nil
    throw "Unable to create stdout logger " unless @stdout_logger!=nil

  

    case @info_level
    when "info"
      @stdout_logger.level=Logger::INFO
    when "debug"    
      @stdout_logger.level=Logger::DEBUG
    when "warn"
      @stdout_logger.level=Logger::WARN      
    end

  end

  # Write a message to all logger objects
  #
  def log(message,level)
    if ( @stdout_logger == nil || @file_logger == nil)
      initialize_loggers
    end
    @stdout_logger.send(level,message)
    @file_logger.send(level,message)        
  end

  def path_for_builtin_database(dbname)
    "#{self.protein_database_root}/#{dbname}/current.fasta"
  end


  def dbexist?(dbname)
    Pathname.new("#{self.protein_database_root}/#{dbname}").exist?
  end

  # Based on the database shortname and global database path, find the most current version of the required database
  # If dbname corresponds to a folder in the dbroot this function returns the path of the database with an extension 
  # appropriate to the database type
  #
  # If dbname is a full path to a file this tool will first import the file as a temporary database 
  # and will then return its full path
  #
  def current_database_for_name(dbname)
    dbroot=self.protein_database_root
    
    throw "Protein database directory not specified" unless dbroot!=nil
    throw "Protein database directory #{dbroot} does not exist" unless Pathname(dbroot).exist?
    
    # Remove any trailing slashes or spaces from the end of dbroot if present
    #
    dbroot.sub!(/(\/*\s*)$/,"")
    
    return path_for_builtin_database(dbname)
  
  end


   # Runs the given command in a local shell
   # 
   def run_local(command_string)
     self.log("Command: #{command_string} started",:info)
     status = Open4::popen4("#{command_string} ") do |pid, stdin, stdout, stderr|
       puts "PID #{pid}" 

       stdout.each { |line| self.log(line.chomp,:info) }

       stderr.each { |line| self.log(line.chomp,:warn) }

     end
     if ( status!=0 )
       # We terminated with some error code so log as an error
       self.log( "Command: #{command_string} exited with status #{status.to_s}",:error)
     else
       self.log( "Command: #{command_string} exited with status #{status.to_s}",:info)      
     end
     status     
   end

   def import_fasta_database(dbroot,path_to_fasta_file)
     
     tmp_dbroot=Pathname.new("#{dbroot}/tmp/")

     dest_fasta_file_name=Pathname.new(path_to_fasta_file).basename
     dest_fasta_file_path=Pathname.new("#{tmp_dbroot}#{dest_fasta_file_name}")

     if ( !dest_fasta_file_path.exist? )

       Dir.mkdir(tmp_dbroot) unless tmp_dbroot.exist? && tmp_dbroot.directory?

       throw "Unable to make temporary database directory #{tmp_dbroot}" unless tmp_dbroot.exist?
       
       link_cmd = "ln -s #{path_to_fasta_file} #{dest_fasta_file_path}"
       
       result= %x[#{link_cmd}]
       p result
     end

     check_cmd="#{self.ncbi_tools_bin}/blastdbcmd -info -db #{dest_fasta_file_path}"
     result = %x[#{check_cmd}]

     if ( result=="")
       
       throw "Unable to create temporary database #{dest_fasta_file_path}" unless dest_fasta_file_path.exist?
       cmd="#{self.makeblastdb} -in #{dest_fasta_file_path} -parse_seqids"
       p cmd
       self.run_local(cmd)
       
     end

     return dest_fasta_file_path.to_s
     
   end



end