require 'protk/constants'
require 'pathname'
	
$protk_env=Constants.new
$this_dir=File.dirname(__FILE__)

def swissprot_installed
	Pathname.new("#{$protk_env.protein_database_root}/#{$protk_env.uniprot_sprot_annotation_database}").exist?
end

RSpec.configure do |c|
	c.filter_run_excluding :broken => true unless swissprot_installed
end
