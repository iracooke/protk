$VERBOSE=nil

require 'pathname'

# A GalaxyStager object represents a single file whose path needs to be staged for use within galaxy
#
# Staging occurs on init and generally involves creating a symlink from the original path to the staged path
#
# By keeping GalaxyStager objects around until script completion it is possible to perform a 
# restore_references operation in script output files.
#
class GalaxyStager 
  attr_accessor :staged_path
  attr_accessor :staged_base_path

  # Initialize and perform staging
  #
  def initialize(original_path, options = {})
    options = { :name => nil, :extension => '', :force_copy => false }.merge(options)

    @extension = options[:extension]
    @original_path = Pathname.new(original_path)
    @wd = Dir.pwd
    @staged_name = options[:name] || @original_path.basename
    @staged_base_path = File.join(@wd, @staged_name)
    @staged_path = "#{@staged_base_path}#{@extension}"
    if options[:force_copy]
      FileUtils.copy(@original_path, @staged_path)
    else      
      File.symlink(@original_path, @staged_path) unless File.symlink?@staged_path
    end
  end

  def replace_references(in_file,replacement)
    GalaxyStager.replace_references(in_file, @original_path, replacement)
  end

  def restore_references(in_file, options = {})
    path = options[:base_only] ? @staged_path.gsub(/#{@extension}/,"") : @staged_path
    GalaxyStager.replace_references(in_file, path, @original_path)
  end

  def self.replace_references(in_file, from_path, to_path)
    puts "Replacing #{from_path} with #{to_path} in #{in_file}"
    cmd="ruby -pi -e \"gsub('#{from_path}', '#{to_path}')\" #{in_file}"
    %x[#{cmd}]
  end

end
