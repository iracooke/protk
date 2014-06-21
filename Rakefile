

require 'rspec/core/rake_task'
require "rake/extensiontask"


# We can do rake EXAMPLE="peptide_prophet" to run tasks matching peptide_prophet
#
RSpec::Core::RakeTask.new(:spec) do |task|
	example=ENV['EXAMPLE']
	task.rspec_opts="-e #{example}" if example
end

task :spec => :compile
task :compile => :clean

Rake::ExtensionTask.new "decoymaker" do |ext|
	ext.ext_dir = 'ext/decoymaker'	
	ext.lib_dir = "lib/protk/"
end

CLEAN.include('lib/**/*{.o,.log,.so,.bundle}')

task :default => [:spec]


