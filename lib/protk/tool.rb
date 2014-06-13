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

      if ( option_support.include? :prefix_suffix)
      
        @options.output_prefix = ""
        opts.on( '-b', '--output-prefix pref', 'A string to prepend to the name of output files' ) do |prefix|
          @options.output_prefix = prefix
        end

        @options.output_suffix = ""
        opts.on( '-e', '--output-suffix suff', 'A string to append to the name of output files' ) do |suffix|
          @options.output_suffix = suffix
        end
        
      end
      
      if ( option_support.include? :explicit_output )
        @options.explicit_output = nil
        opts.on( '-o', '--output out', 'An explicitly named output file.' ) do |out|
          @options.explicit_output = out
        end
      end
         
      if ( option_support.include? :over_write)
            
        @options.over_write=false
        opts.on( '-r', '--replace-output', 'Dont skip analyses for which the output file already exists' ) do  
          @options.over_write = true
        end
        
      end
      
       
      opts.on( '-h', '--help', 'Display this screen' ) do
        puts opts
        exit
      end
       
    end

  end
  




   # Create and return a full base path (without extension) representing the output file for this analysis
   # Optionally provide the extension to be removed (if not provided it will be inferred)
   #
   def output_base_path(output_file,ext=nil)

     output_path=Pathname.new(output_file)
     throw "Error: Output directory #{output_path.dirname} does not exist" unless output_path.dirname.exist?
     dir=output_path.dirname.realpath.to_s
     basename=output_path.basename.to_s
     if ( ext==nil)
       ext=output_path.extname    
     end
     base_name=basename.gsub(/#{ext}$/,"")

     "#{dir}/#{@options.output_prefix}#{base_name}#{@options.output_suffix}"
   end


   def check_options(mandatory=[])
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
      puts tool.option_parser                                              
      return false                                                         
    end
    return true
   end

   # Create a full base path (without extension) representing the input file for this analysis
   # Optionally provide the extension to be removed (if not provided it will be inferred)
   #
   def input_base_path(input_file,ext=nil)
     input_path=Pathname.new(input_file)
     throw "Error: Input directory #{input_path.dirname} does not exist" unless input_path.dirname.exist?
     dir=input_path.dirname.realpath.to_s
     if ( ext==nil)
       ext=input_path.extname    
     end
     base_name=input_path.basename.to_s.gsub(/#{ext}$/,"")
     "#{dir}/#{base_name}"
   end
   
   
   # Run the search tool using the given command string and global environment
   #
   def run(cmd,genv,autodelete=true)
    cmd_runner=CommandRunner.new(genv)
    cmd_runner.run_local(cmd)
   end
   
  
end