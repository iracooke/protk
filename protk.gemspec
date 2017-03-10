Gem::Specification.new do |s|
  s.name        = 'protk'
  s.version     = '1.4.4.beta3'
  s.date        = '2015-10-21'
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Proteomics Toolkit"
  s.description = "Commandline tools for proteomics"
  s.post_install_message = "Now run protk_setup.rb to install third party tools"
  s.authors     = ["Ira Cooke"]
  s.email       = 'iracooke@gmail.com'
  s.licenses    = ['LGPL-2.1'] 

  s.files        = Dir["{lib}/**/*.rb","{lib}/protk/*.rake", "bin/*", "LICENSE", "*.md","{lib}/**/data/*"] + Dir.glob('lib/**/*.rb') + Dir.glob('ext/**/*.{c,h,rb}')
  s.require_path = 'lib'

  s.extensions = ['ext/decoymaker/extconf.rb']

  s.add_runtime_dependency 'open4', '~> 1.3' , '>= 1.3.0'
  s.add_runtime_dependency 'bio', '~> 1.4.3', '>= 1.4.3'

  s.add_runtime_dependency 'rest-client','~> 1.6.7', '>= 1.6.7'
  s.add_runtime_dependency 'net-ftp-list',"~>3.2.5" ,">=3.2.5"
#  s.add_runtime_dependency 'libxml-ruby',"~>2.7", ">=2.7.0"
  s.add_runtime_dependency 'libxml-ruby',"~>2.9", ">=2.9.0"

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-mocks', '~> 3.0'
  s.add_development_dependency 'rake-compiler', '~> 0'
  s.add_development_dependency 'byebug', '~> 3.5'
  s.add_runtime_dependency 'sqlite3','~>0'

  s.homepage    = 'http://rubygems.org/gems/protk'

  s.executables = ['protk_setup.rb','manage_db.rb']
  s.executables = s.executables + ['tandem_search.rb','mascot_search.rb','omssa_search.rb','msgfplus_search.rb']
  s.executables = s.executables + ['mascot_to_pepxml.rb','tandem_to_pepxml.rb']
  s.executables = s.executables + ['make_decoy.rb']
  s.executables = s.executables + ['repair_run_summary.rb','add_retention_times.rb']
  s.executables = s.executables + ['peptide_prophet.rb','interprophet.rb','protein_prophet.rb']
  s.executables = s.executables + ['pepxml_to_table.rb']
  s.executables = s.executables + ['unimod_to_loc.rb']
  s.executables = s.executables + ['uniprot_mapper.rb']
  s.executables = s.executables + ['sixframe.rb','augustus_to_proteindb.rb','maker_to_proteindb.rb','protxml_to_gff.rb']
  s.executables = s.executables + ['protxml_to_table.rb']
  s.executables = s.executables + ['swissprot_to_table.rb']
  s.executables = s.executables + ['protxml_to_psql.rb']
  s.executables = s.executables + ['mzid_to_protxml.rb','mzid_to_pepxml.rb']
  s.executables = s.executables + ['spectrast_create.rb','spectrast_filter.rb']
  s.executables = s.executables + ['filter_psms.rb']
end

