#
# This file is part of protk
# Created by Ira Cooke 16/12/2010
#
# Provides common functionality used by all tools.
#

require 'ostruct'
require 'optparse'
require 'pathname'
require 'protk/command_runner'

class Tool

  # Options set from the command-line
  #
  attr :options, false
  
  # The option parser used to parse command-line options. 
  #
  attr :option_parser

  attr :options_defined_by_user

  # Prefix for background jobs
  # x = X!Tandem, o=OMSSA, p="Phenyx", m="Mascot"
  # Can't use attr_accessor here because we want this available to subclasses
  #
  def jobid_prefix
    @jobid_prefix
  end

  def jobid_prefix=(p)
    @jobid_prefix=p
  end

  def supported_options
    os_hash=@options.to_h
    # Remove entries entirely related to internal use
    internal_keys=[:library, :inplace, :encoding, :transfer_type, :verbose]
    os_hash.delete_if { |key,val| internal_keys.include? key }
    os_hash
  end

  # Provides direct access to options through methods of the same name
  #
  def method_missing(meth, *args, &block)
    if ( args.length==0 && block==nil)
      @options.send meth
    else
      super
    end
  end
  
  
  def add_value_option(symbol,default_value,opts)
    @options[symbol]=default_value
    @option_parser.on(*opts) do |val|
      @options[symbol]=val
      @options_defined_by_user[symbol]=opts
    end
  end
  
  def add_boolean_option(symbol,default_value,opts)
    @options[symbol]=default_value
    @option_parser.on(*opts) do 
      @options[symbol]=!default_value
      @options_defined_by_user[symbol]=opts
    end
  end


  # Creates an empty options object to hold commandline options
  # Also creates an option_parser with default options common to all tools
  #
  def initialize(option_support=[])
    @jobid_prefix = "x"
    @options = OpenStruct.new
    options.library = []
    options.inplace = false
    options.encoding = "utf8"
    options.transfer_type = :auto
    options.verbose = false
    
    @options_defined_by_user={}

    @option_parser=OptionParser.new do |opts|      

      opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
    end

    if ( option_support.include? :prefix)
      add_value_option(:output_prefix,"",['-b','--output-prefix pref', 'A string to prepend to the name of output files'])
    end

    if ( option_support.include? :over_write)
      add_boolean_option(:over_write,false,['-r', '--replace-output', 'Dont skip analyses for which the output file already exists'])        
    end

    if ( option_support.include? :explicit_output )
      add_value_option(:explicit_output,nil,['-o', '--output out', 'An explicitly named output file.'])
    end

    if ( option_support.include? :threads )
      add_value_option(:threads,1,['-n','--threads num','Number of processing threads to use. Set to 0 to autodetect an appropriate value'])
    end

  end


   def self.extension_from_filename(filename)
    ext=""
    case filename.chomp
    when /\.pep\.xml/
      ext=".pep.xml"
    when /\.prot\.xml/
      ext=".prot.xml"
    else
      ext=Pathname.new(filename.chomp).extname
    end
    ext
   end

  def self.default_output_path(input_path,newext,prefix,suffix)
    dir=Pathname.new(input_path).dirname.realpath.to_s
    basename=Pathname.new(input_path).basename.to_s
    oldext=Tool.extension_from_filename(input_path)
    basename=basename.gsub(/#{oldext}$/,"")
    "#{dir}/#{prefix}#{basename}#{suffix}#{newext}"
   end

   def check_options(require_input_file=false,mandatory=[])
    # Checking for required options
    begin
      self.option_parser.parse!
      missing = mandatory.select{ |param| self.send(param).nil? }
      if not missing.empty?                                            
        puts "Missing options: #{missing.join(', ')}"                  
        puts self.option_parser                                                  
        return false                                                        
      end                                                              
    rescue OptionParser::InvalidOption, OptionParser::MissingArgument      
      puts $!.to_s                                                           
      puts self.option_parser                                              
      return false                                                         
    end

    if ( require_input_file && ARGV[0].nil? )
      puts "You must supply an input file"
      puts self.option_parser 
      return false
    end

    return true
   end   
   
   # Run the search tool using the given command string and global environment
   #
   def run(cmd,genv,autodelete=true)
    cmd_runner=CommandRunner.new(genv)
    cmd_runner.run_local(cmd)
   end
   
  
end