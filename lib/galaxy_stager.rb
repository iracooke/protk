require 'pathname'

class GalaxyStager 
  attr_accessor :staged_path

  def initialize(original_path, options = {})
  	options = { :name => nil, :extension => '' }.merge(options)
  	@original_path = Pathname.new(original_path)
  	@wd = Dir.pwd
  	staged_name = options[:name] || @original_path.basename
  	@staged_path = File.join(@wd, "#{staged_name}#{options[:extension]}")
  	File.symlink(@original_path, @staged_path)
  end

  def restore_references(in_file)
    GalaxyStager.replace_references(in_file, @staged_path, @original_path)
  end

  def self.replace_references(in_file, from_path, to_path)
    cmd="ruby -pi -e \"gsub('#{from_path}', '#{to_path}')\" #{in_file}"
    %x[#{cmd}]
  end

end