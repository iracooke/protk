#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 14/12/2010
#
# Runs an MS/MS search using the Mascot search engine
#

$VERBOSE=nil

require 'protk/constants'
require 'protk/command_runner'
require 'protk/search_tool'
require 'rest_client'

def login(mascot_cgi,username,password)

    authdict={}
    authdict[:username]=username
    authdict[:password]=password
    authdict[:action]="login"
    authdict[:savecookie]="1"

    p "Logging in to #{mascot_cgi}/login.pl"
    p authdict
    response = RestClient.post "#{mascot_cgi}/login.pl", authdict

    cookie = response.cookies
    cookie
end

def download_datfile(mascot_cgi,results_date,results_file,explicit_output,openurlcookie)
    mascot_xcgi = "#{mascot_cgi.chomp('cgi')}x-cgi"
    get_url= "#{mascot_xcgi}/ms-status.exe?Autorefresh=false&Show=RESULTFILE&DateDir=#{results_date}&ResJob=#{results_file}"
    $genv.log("Getting results file at #{get_url}",:info)
    
    if ( explicit_output!=nil)
        output_path=explicit_output
    else
        output_path="#{results_file}"
    end

    require 'open-uri'
    open("#{output_path}", 'wb') do |file|
        file << open("#{get_url}","Cookie"=>openurlcookie).read
    end
end


def search_params_dictionary(search_tool,input_file)
    var_mods = search_tool.var_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject {|e| e.empty? }.join(",")
    fix_mods = search_tool.fix_mods.split(",").collect { |mod| mod.lstrip.rstrip }.reject { |e| e.empty? }.join(",")

    # None is given by a an empty galaxy multi-select list and we need to turn it into an empty string
    #
    var_mods=""  if var_mods=="None"
    fix_mods="" if fix_mods=="None"

    postdict={}
    postdict[:SEARCH]="MIS" 
    postdict[:CHARGE]=search_tool.allowed_charges
    postdict[:CLE]=search_tool.enzyme
    postdict[:PFA]=search_tool.missed_cleavages
    postdict[:COM]="Protk"
    postdict[:DB]=search_tool.database
    postdict[:INSTRUMENT]=search_tool.instrument
    postdict[:IT_MODS]=var_mods
    postdict[:ITOL]=search_tool.fragment_tol
    postdict[:ITOLU]=search_tool.fragment_tolu
    postdict[:MASS]=search_tool.precursor_search_type
    postdict[:MODS]=fix_mods
    postdict[:REPORT]="AUTO"
    postdict[:TAXONOMY]="All entries"
    postdict[:TOL]=search_tool.precursor_tol
    postdict[:TOLU]=search_tool.precursor_tolu
    postdict[:USEREMAIL]=search_tool.email
    postdict[:USERNAME]=search_tool.username
    postdict[:FILE]=File.new(input_file)
    postdict[:FORMVER]='1.01'
    postdict[:INTERMEDIATE]=''

    postdict
end

# Environment with global constants
#
$genv=Constants.new

# Setup specific command-line options for this tool. Other options are inherited from SearchTool
#
search_tool=SearchTool.new([:explicit_output,:over_write,:database,:enzyme,
    :modifications,:instrument,:mass_tolerance,
    :mass_tolerance_units,:precursor_search_type,:missed_cleavages])

search_tool.jobid_prefix="o"

search_tool.option_parser.banner = "Run a Mascot msms search on a set of mgf input files.\n\nUsage: mascot_search.rb [options] msmsfile.mgf"
search_tool.options.output_suffix="_mascot"

search_tool.options.mascot_server="#{$genv.default_mascot_server}/mascot/cgi"

search_tool.options.allowed_charges="1+,2+,3+"
search_tool.option_parser.on(  '--allowed-charges ac', 'Allowed precursor ion charges. Default=1+,2+,3+' ) do |ac|
 search_tool.options.allowed_charges = ac
end     

search_tool.options.email=""
search_tool.option_parser.on('--email em', 'User email.') do |em|
    search_tool.options.email = em
end

search_tool.options.username=""
search_tool.option_parser.on('--username un', 'Username.') do |un|
    search_tool.options.username = un
end

search_tool.options.mascot_server="www.matrixscience.com"
search_tool.option_parser.on( '-S', '--server url', 'The url to the cgi directory of the mascot server' ) do |url| 
    search_tool.options.mascot_server=url
end

search_tool.options.mascot_server=""
search_tool.option_parser.on('--username un', 'Username.') do |un|
    search_tool.options.username = un
end

search_tool.options.httpproxy=nil
search_tool.option_parser.on( '--proxy url', 'The url to a proxy server' ) do |urll| 
    search_tool.options.httpproxy=urll
end

search_tool.options.mascot_password=""
search_tool.option_parser.on( '--password psswd', 'Password to use when Mascot security is enabled' ) do |psswd| 
    search_tool.options.mascot_password=psswd
end

search_tool.options.use_security=FALSE
search_tool.option_parser.on( '--use-security', 'When Mascot security is enabled this is required' ) do  
    search_tool.options.use_security=TRUE
end

search_tool.options.export_format="mascotdat"
search_tool.option_parser.on( '--export format', 'Save results in a specified format. Only mascotdat is currently supported' ) do |format| 
    search_tool.options.export_format=format
end

search_tool.options.timeout=200
search_tool.option_parser.on( '--timeout seconds', 'Timeout for sending data file to mascot in seconds' ) do |seconds| 
    search_tool.options.timeout=seconds.to_i
end

exit unless search_tool.check_options 

if ( ARGV[0].nil? )
    puts "You must supply an input file"
    puts search_tool.option_parser 
    exit
end

fragment_tol = search_tool.fragment_tol
precursor_tol = search_tool.precursor_tol

mascot_cgi=search_tool.mascot_server.chomp('/')

unless ( mascot_cgi =~ /^http[s]?:\/\//)
    mascot_cgi  = "http://#{mascot_cgi}"
end

RestClient.proxy=search_tool.httpproxy if search_tool.httpproxy
$genv.log("Var mods #{search_tool.var_mods} and fixed #{search_tool.fix_mods}",:info)

cookie=""
openurlcookie=""

if ( search_tool.use_security)
    $genv.log("Logging in",:info)
    cookie = login(mascot_cgi,search_tool.username,search_tool.mascot_password)
    openurlcookie = "MASCOT_SESSION=#{cookie['MASCOT_SESSION']}; MASCOT_USERID=#{cookie['MASCOT_USERID']}; MASCOT_USERNAME=#{cookie['MASCOT_USERNAME']}"
end

postdict = search_params_dictionary search_tool, ARGV[0]
$genv.log("Sending #{postdict}",:info)

#site = RestClient::Resource.new(mascot_cgi, timeout=300)
#search_response=site['/nph-mascot.exe?1'].post , postdict, {:cookies=>cookie}

search_response=RestClient::Request.execute(:method => :post, :url => "#{mascot_cgi}/nph-mascot.exe?1", :payload => postdict,:headers=>{:cookies=>cookie},:timeout => search_tool.options.timeout, :open_timeout => 10)


#search_response=RestClient.post "#{mascot_cgi}/nph-mascot.exe?1", postdict, {:cookies=>cookie}

$genv.log("Mascot search response was #{search_response}",:info)

# Look for an error if there is one
error_result= /Sorry, your search could not be performed(.*)/.match(search_response)
if ( error_result != nil )
    puts error_result[0]
    $genv.log("Mascot search failed with response #{search_response}",:warn)
    throw "Mascot search failed with response #{search_response}"
elsif (search_tool.export_format=="mascotdat")
    # Search for the location of the mascot data file in the response
    results=/master_results_?2?\.pl\?file=\.*\/data\/(.*)\/(.+\.dat)/.match(search_response)
    results_date=results[1]
    results_file=results[2]

    download_datfile mascot_cgi, results_date, results_file,search_tool.explicit_output,openurlcookie
else
    results=/master_results_?2?\.pl\?file=(\.*\/data\/.*\/.+\.dat)/.match(search_response)
    results_file = results[1]
    export_results mascot_cgi,cookie,results_file,search_tool.export_format, openurlcookie
#    export_results mascot_cgi,cookie,results_file,search_tool.export_format
end

