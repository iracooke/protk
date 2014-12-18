#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 20/10/2012
#
# Post-install setup for protk. 
# Installs third party tools
#
require 'protk/constants'

toolname=ARGV[0]

if ARGV[1]=='--change-location'
	location=ARGV[2]
	p "Changing default location for #{toolname} to #{location}"
	env=Constants.instance
	env.update_user_config({"#{toolname}_root"=>location})
	exit
end


require 'protk/setup_tool'
require 'yaml'
require 'pp'


# Setup specific command-line options for this tool. Other options are inherited from Tool
#
tool=SetupTool.new
tool.option_parser.banner = "Post install tasks for protk.\nUsage: protk_setup.rb [options] toolname"

tool.option_parser.parse!

if ( ARGV.length < 1)
	p "You must supply a setup task [all,system_packages]"
	p tool.option_parser
	exit
end

env=Constants.instance

toolname=ARGV.shift

p "Installing #{toolname}"
tool.install toolname
