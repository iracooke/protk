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
  attr :env
  
  # These are logger attributes with thresholds as indicated
  #  DEBUG < INFO < WARN < ERROR < FATAL < UNKNOWN
  #Debug (development mode) or Info (production)
  #
  attr :stdout_logger 
  
  #Warn
  #
  attr :file_logger 




  # Provides direct access to constants through methods of the same name
  # This will be used for all constants other than paths
  #
  def method_missing(method)
    @env[method.to_s]
  end

  # Simplify setup of ProtK, by not requiring absolute paths
  # to executables
  def build_path(bin_dir, executable)
    if FileTest.exists?(bin_dir) or @env['force_absolute_path']
      File.join(bin_dir, executable)
    else
      executable
    end
  end

  # Some constants are paths. They need to be translated into real paths before being returned
  #
  
  def bin
    return "#{File.dirname(__FILE__)}/../bin"
  end
  
  def tpp_bin
    path=@env['tpp_bin']
    if ( path =~ /^\// )
      return path
    else
      return "#{File.dirname(__FILE__)}/../#{@env['tpp_bin']}"
    end
  end
  
  def omssa_bin
    path=@env['omssa_bin']
    if ( path =~ /^\// )
      return path
    else
      return "#{File.dirname(__FILE__)}/../#{@env['omssa_bin']}"
    end
  end

  def openms_bin
    path=@env['openms_bin']
    if ( path =~ /^\// )
      return path
    else
      return "#{File.dirname(__FILE__)}/../#{@env['openms_bin']}"
    end
  end
  
  def protein_database_root
    path=@env['protein_database_root']
    if ( path =~ /^\// )
      return path
    else
      return "#{File.dirname(__FILE__)}/../#{@env['protein_database_root']}"
    end
  end
  
  def database_downloads
    return "#{self.protein_database_root}/downloads"
  end
  
  def ncbi_tools_bin
    path=@env['ncbi_tools_bin']
    if ( path =~ /^\// )
      return path
    else
      return "#{File.dirname(__FILE__)}/../#{@env['ncbi_tools_bin']}"   
    end 
  end
  
  def log_file
    path=@env['log_file']
    if ( path =~ /^\// )
      return path
    else
      return "#{File.dirname(__FILE__)}/../#{@env['log_file']}"
    end
  end


  # Read the global constants file and initialize our class @env variable
  # Initialize loggers
  #
  def initialize
        
    config_yml = YAML.load_file "#{File.dirname(__FILE__)}/../config.yml"


    throw "Unable to read the config file at #{File.dirname(__FILE__)}/../config.yml" unless config_yml!=nil

    run_setting=config_yml['run_setting']    
    throw "No run_setting found in config file" unless run_setting!=nil

    @env=config_yml[run_setting]    
    throw "No data found for run setting #{run_setting} in config file" unless @env!=nil

    @stdout_logger=Logger.new(STDOUT)
    @file_logger=Logger.new(self.log_file,'daily')

    throw "Unable to create file logger at path #{self.log_file}" unless @file_logger!=nil
    throw "Unable to create stdout logger " unless @stdout_logger!=nil

  
    info_level=config_yml['message_level']

    case info_level
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


#
# OLD DATABASE ACCESS/MANAGEMENT METHODS #
#

#  def path_for_builtin_database(dbroot,dbname,db_type,db_suffix="")
#    
#    current_dbroot=Pathname.new("#{dbroot}/#{dbname}")
#    throw "Error: Specified database #{current_dbroot.to_s} does not exist" unless current_dbroot.exist?
#    
#    candidates=current_dbroot.children
#    
#    # Filter candidates with the right filenames
#    #
#    candidates = candidates.find_all { |dbpath|
#      dbstring=dbpath.basename.to_s
#      /#{dbname}_(\d+)#{db_suffix}\./i.match(dbstring)!=nil
#    }
#    
#    dates=candidates.collect { |dbpath| 
#       dbstring=dbpath.basename.to_s
#       m=/#{dbname}_(\d+)#{db_suffix}\./i.match(dbstring)
#       m[1].to_i
#     }
#     
#     maxdate=dates[0]
#     dates.each { |d| 
#       if ( d > maxdate )
#         maxdate=d
#       end
#     }
#     extension=""
#     case db_type
#     when :fasta
#       extension=".fasta"
#     end
#
#     # Enabling this will force a transition to a new db naming scheme. Better one though
#     #
#     #   "#{dbroot}/#{dbname.downcase}/#{dbname.downcase}_#{maxdate}_DECOY#{extension}"
#
#          
#     "#{dbroot}/#{dbname}/#{dbname.downcase}_#{maxdate}#{db_suffix}#{extension}"
#   end

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
       cmd="#{self.ncbi_tools_bin}/makeblastdb -in #{dest_fasta_file_path} -parse_seqids"
       p cmd
       self.run_local(cmd)
       
     end

     return dest_fasta_file_path.to_s
     
   end



end