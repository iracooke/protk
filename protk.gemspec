Gem::Specification.new do |s|
  s.name        = 'protk'
  s.version     = '1.2.6.pre6'
  s.date        = '2013-10-28'
  s.platform    = Gem::Platform::RUBY
  s.summary     = "Proteomics Toolkit"
  s.description = "A bunch of tools for proteomics"
  s.post_install_message = "Now run protk_setup.rb to install third party tools and manage_db.rb to install databases."
  s.authors     = ["Ira Cooke"]
  s.email       = 'iracooke@gmail.com'

  s.files        = Dir["{lib}/**/*.rb","{lib}/protk/*.rake", "bin/*", "LICENSE", "*.md","{lib}/**/data/*"] + Dir.glob('lib/**/*.rb') + Dir.glob('ext/**/*.{c,h,rb}')
  s.require_path = 'lib'

  s.extensions = ['ext/protk/decoymaker/extconf.rb']

  s.add_runtime_dependency 'ftools', '~> 0.0', '>= 0.0.0'
  s.add_runtime_dependency 'open4', '~> 1.3', '>= 1.3.0'
  s.add_runtime_dependency 'bio', '~> 1.4', '>= 1.4.3'

  s.add_runtime_dependency 'rest-client','~> 1.6.7', '>= 1.6.7'
  s.add_runtime_dependency 'net-ftp-list',"~>3.2.5" ,">=3.2.5"
  s.add_runtime_dependency 'spreadsheet',"~>0.7.4", ">=0.7.4"
  s.add_runtime_dependency 'libxml-ruby',"~>2.7", ">=2.7.0"
  s.add_runtime_dependency 'mascot-dat', "~>0.3.1", ">=0.3.1"
  s.add_runtime_dependency 'bio-blastxmlparser',"~>1.1.1", ">=1.1.1"

  s.add_development_dependency 'rspec', '~> 3.0'
  s.add_development_dependency 'rspec-mocks', '~> 3.0'

  s.homepage    = 'http://rubygems.org/gems/protk'
  s.executables = ['protk_setup.rb','manage_db.rb']
  s.executables = s.executables + ['asapratio.rb']
  s.executables = s.executables + ['libra.rb']
  s.executables = s.executables + ['xpress.rb']
  s.executables = s.executables + ['tandem_search.rb','mascot_search.rb','omssa_search.rb','msgfplus_search.rb']
  s.executables = s.executables + ['mascot_to_pepxml.rb','tandem_to_pepxml.rb','file_convert.rb']
  s.executables = s.executables + ['make_decoy.rb']
  s.executables = s.executables + ['correct_omssa_retention_times.rb','repair_run_summary.rb','add_retention_times.rb']
  s.executables = s.executables + ['peptide_prophet.rb','interprophet.rb','protein_prophet.rb']
  s.executables = s.executables + ['pepxml_to_table.rb','xls_to_table.rb','annotate_ids.rb']
  s.executables = s.executables + ['unimod_to_loc.rb','generate_omssa_loc.rb']
  s.executables = s.executables + ['uniprot_mapper.rb']
  s.executables = s.executables + ['feature_finder.rb','toppas_pipeline.rb']
  s.executables = s.executables + ['gffmerge.rb','sixframe.rb','augustus_to_proteindb.rb','protxml_to_gff.rb']
  s.executables = s.executables + ['uniprot_annotation.rb','protxml_to_table.rb']
  s.executables = s.executables + ['blastxml_to_table.rb']
  
end

