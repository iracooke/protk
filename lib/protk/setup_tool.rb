
require 'optparse'
require 'pathname'
require 'protk/tool'

require 'rake'
require 'pp'

include Rake::DSL

Rake.application.init 'protk_setup'
Rake.application.rake_require 'protk/setup_rakefile'

class SetupTool < Tool

	def install toolname
		Rake.application.invoke_task toolname
	end

end