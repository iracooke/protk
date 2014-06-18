require 'rspec/core/rake_task'
require "rake/extensiontask"


RSpec::Core::RakeTask.new('spec')

task :spec => :compile
task :compile => :clean

Rake::ExtensionTask.new "decoymaker" do |ext|
	ext.ext_dir = 'ext/decoymaker'	
	ext.lib_dir = "lib/protk/"
end

CLEAN.include('lib/**/*{.o,.log,.so,.bundle}')

task :default => [:spec]


