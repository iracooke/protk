Gem::Specification.new do |s|
  s.name        = 'protk'
  s.version     = '1.1.0.pre'
  s.date        = '2012-10-19'
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Proteomics Toolkit"
  s.description = "A bunch of tools for proteomics"
  s.post_install_message = "Now run protk_setup.rb to install third party tools and manage_db.rb to install databases."
  s.authors     = ["Ira Cooke"]
  s.email       = 'iracooke@gmail.com'

  s.files        = Dir["{lib}/**/*.rb","{lib}/protk/*.rake", "bin/*", "LICENSE", "*.md","{lib}/**/data/*"] + Dir.glob('lib/**/*.rb') + Dir.glob('ext/**/*.{c,h,rb}')
  s.require_path = 'lib'

  s.extensions = ['ext/protk/extconf.rb']

  s.add_runtime_dependency "ftools", [">= 0.0.0"]
  s.add_runtime_dependency "open4", [">= 1.3.0"]
  s.add_runtime_dependency "bio", [">= 1.4.3"]
  s.add_runtime_dependency "rest-client", [">= 1.6.7"]
  s.add_runtime_dependency "net-ftp-list", [">=3.2.5"]
  s.add_runtime_dependency "spreadsheet", [">=0.7.4"]
  s.add_runtime_dependency "libxml-ruby", [">=2.3.3"]


  s.add_development_dependency 'rspec', '~> 2.5'

  s.homepage    = 'http://rubygems.org/gems/protk'
  s.executables = ['protk_setup.rb','manage_db.rb','tandem_search.rb','make_decoy.rb','repair_run_summary.rb']
  s.executables = s.executables + ['annotate_ids.rb','correct_omssa_retention_times.rb','file_convert.rb']
  s.executables = s.executables + ['generate_omssa_loc.rb','interprophet.rb','mascot_search.rb','mascot_to_pepxml.rb']
  s.executables = s.executables + ['omssa_search.rb','peptide_prophet.rb','pepxml_to_table.rb','protein_prophet.rb']
  s.executables = s.executables + ['unimod_to_loc.rb','xls_to_table.rb']
end
