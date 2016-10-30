# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Initialises global constants. 
# All tools should source this file.
#
require 'yaml'
require 'logger'
require 'pathname'
require 'singleton'

class Constants
  include Singleton
  # A Hash holding all the constants
  #
  @env
  
  # These are logger attributes with thresholds as indicated
  #  DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
  # Debug (development mode) or Info (production)
  #
  @stdout_logger 
  
  #Warn
  #
  @file_logger 



  attr :info_level
  attr :protk_dir
  attr :data_lib_dir
  attr_accessor :info_level

  # Provides direct access to constants through methods of the same name
  # This will be used for all constants other than paths
  #
  def method_missing(method)

    from_env = @env[method.to_s]
    throw "#{method} is undefined" unless from_env!=nil
    from_env
  end


  # Some constants are paths. They need to be translated into real paths before being returned
  #
  
  def bin
    return "#{@protk_dir}/bin"
  end
  
  def tpp_root
      "#{@protk_dir}/tools/tpp"
  end

  
  def omssa_root
      "#{@protk_dir}/tools/omssa"
  end
  
  def msgfplus_root
    "#{@protk_dir}/tools/msgfplus"
  end

  def get_path_for_executable(exec_name_list)
    exec_name_list.each do |exec_name| 
      exec_path=%x[which #{exec_name}]
      exec_path.chomp
      return exec_path unless !exec_path || exec_path.length==0
    end
    throw "Unable to locate #{exec_name_list}"
  end

  def tandem_bin
    get_path_for_executable ["tandem","tandem.exe"]
  end

  def msgfplusjar
    msgfplus_path=%x[which MSGFPlus.jar]
    msgfplus_path.chomp
  end

  def pwiz_root
      return "#{@protk_dir}/tools/pwiz"
  end

  def openms_root
      "#{@protk_dir}/tools/openms"
  end

  def tandem_root
      "#{@protk_dir}/tools/tandem"
  end

  def makeblastdb
    makeblastdbpath=%x[which makeblastdb]
    makeblastdbpath.chomp
  end

  def blastdbcmd
    path=%x[which blastdbcmd]
    path.chomp
  end

  def mascot2xml
    path=%x[which Mascot2XML]
    path.chomp
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
      "#{@protk_dir}/tools/blast"   
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
  def initialize() 

    @data_lib_dir="#{File.dirname(__FILE__)}/data"
    @protk_dir="#{Dir.home}/.protk"

    if ( ENV['PROTK_INSTALL_DIR']!=nil )
      p "Using protk install dir from shell"
      @protk_dir=ENV['PROTK_INSTALL_DIR']
    end

    # Load Protk Defaults
    #
    default_config_yml = YAML.load_file "#{File.dirname(__FILE__)}/data/default_config.yml"
    throw "Unable to read the config file at #{File.dirname(__FILE__)}/data/default_config.yml" unless default_config_yml!=nil

    # User-defined defaults override protk defaults
    #
    user_config_yml = nil
    user_config_yml = YAML.load_file "#{@protk_dir}/config.yml" if File.exist? "#{@protk_dir}/config.yml"
    if ( user_config_yml !=nil )
      @env = default_config_yml.merge user_config_yml
    else
      @env=default_config_yml
    end

    protk_tool_dirs=["tpp/bin","omssa","openms/bin","msgfplus","blast/bin","pwiz","tandem/bin"]

    # Construct the PATH variable by prepending our preferred paths
    #
    protk_paths=[]

    # Add PATHs if PROTK_XXX_ROOT is defined
    #
    protk_tool_dirs.each do |tooldir|  
      env_value = ENV["PROTK_#{tooldir.upcase}_ROOT"]
      if ( env_value!=nil)
        protk_paths<<env_value
      end
      protk_paths<<"#{@protk_dir}/tools/#{tooldir}"
    end

    original_path=ENV['PATH']
    protk_paths<<original_path


    ENV['PATH']=protk_paths.join(":")

    # puts "Path #{ENV['PATH']}"
    throw "No data found in config file" unless @env!=nil

    @info_level="fatal"
    @info_level=default_config_yml['message_level'] unless default_config_yml['message_level'].nil?

  end


  def update_user_config(dict)
    user_config_yml = YAML.load_file "#{self.protk_dir}/config.yml" if File.exist? "#{self.protk_dir}/config.yml"

    if ( user_config_yml !=nil )
      dict = user_config_yml.merge dict 
    end

    File.open("#{self.protk_dir}/config.yml", "w") {|file| file.puts(dict.to_yaml) }

  end

  def initialize_loggers
    log_dir = Pathname.new(self.log_file).dirname
    log_dir.mkpath unless log_dir.exist?

    @stdout_logger=Logger.new(STDOUT)
    @file_logger=Logger.new(self.log_file)

    throw "Unable to create file logger at path #{self.log_file}" unless @file_logger!=nil
    throw "Unable to create stdout logger " unless @stdout_logger!=nil

    case @info_level
    when /info/i
      @stdout_logger.level=Logger::INFO
    when /debug/i    
      @stdout_logger.level=Logger::DEBUG
    when /warn/i
      @stdout_logger.level=Logger::WARN
    when /fatal/i
      @stdout_logger.level=Logger::FATAL
    else
      throw "Unknown log level #{@info_level}"
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