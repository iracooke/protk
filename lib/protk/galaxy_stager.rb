$VERBOSE=nil

require 'pathname'

class GalaxyStager 
  attr_accessor :staged_path

  def initialize(original_path, options = {})
    options = { :name => nil, :extension => '', :force_copy => false }.merge(options)
    @extension = options[:extension]
    @original_path = Pathname.new(original_path)
    @wd = Dir.pwd
    @staged_name = options[:name] || @original_path.basename
    @staged_base = File.join(@wd, @staged_name)
    @staged_path = "#{@staged_base}#{@extension}"
    if options[:force_copy]
      FileUtils.copy(@original_path, @staged_path)
    else      
      File.symlink(@original_path, @staged_path) unless File.symlink?@staged_path
    end
  end

  def replace_references(in_file)
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
