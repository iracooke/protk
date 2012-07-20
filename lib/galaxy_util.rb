class GalaxyUtil

  def self.for_galaxy
    for_galaxy = ARGV[0] == "--galaxy"
    ARGV.shift if for_galaxy
    return for_galaxy
  end

end