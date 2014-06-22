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

    $genv.log("Logging in to #{mascot_cgi}/login.pl",:info)

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

    $genv.log("Writing output to #{output_path}",:info)

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

    shorthand_varmods=[]
    shorthand_fixmods=[]

    shorthand_varmods << ['Oxidation (M)'] if search_tool.methionine_oxidation
    shorthand_varmods << ['Acetyl (Protein N-term)'] if search_tool.acetyl_nterm
    shorthand_varmods << ['Deamidated (NQ)'] if search_tool.glyco

    shorthand_fixmods << ['Carbamidomethyl (C)'] if search_tool.carbamidomethyl

    if var_mods.length>0
        var_mods=[var_mods,"#{shorthand_varmods.join(",")}"].join(",") 
    else
        var_mods=shorthand_varmods.join(",")
    end


    if fix_mods.length>0
        fix_mods=[fix_mods,"#{shorthand_fixmods.join(",")}"].join(",")
    else
        fix_mods=shorthand_fixmods.join(",")
    end


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
search_tool=SearchTool.new([
    :explicit_output,
    :over_write,
    :database,
    :enzyme,
    :modifications,
    :methionine_oxidation,
    :carbamidomethyl,
    :glyco,
    :acetyl_nterm,
    :instrument,
    :mass_tolerance,
    :mass_tolerance_units,
    :precursor_search_type,
    :missed_cleavages])

search_tool.option_parser.banner = "Run a Mascot msms search on a set of mgf input files.\n\nUsage: mascot_search.rb [options] msmsfile.mgf"
search_tool.options.output_suffix="_mascot"

search_tool.add_value_option(:mascot_server,"#{$genv.default_mascot_server}/mascot/cgi",['-S', '--server url', 'The url to the cgi directory of the mascot server'])
search_tool.add_value_option(:allowed_charges,"1+,2+,3+",['--allowed-charges ac', 'Allowed precursor ion charges.'])
search_tool.add_value_option(:email,"",['--email em', 'User email.'])
search_tool.add_value_option(:username,"",['--username un', 'Username.'])
search_tool.add_value_option(:httpproxy,nil,['--proxy url', 'The url to a proxy server'])
search_tool.add_value_option(:mascot_password,"",['--password psswd', 'Password to use when Mascot security is enabled'])
search_tool.add_boolean_option(:use_security,false,['--use-security', 'When Mascot security is enabled this is required'])
search_tool.add_value_option(:download_only,nil,['--download-only path', 'Specify a relative path to an existing results file on the server for download eg(20131113/F227185.dat)'])
search_tool.add_value_option(:timeout,200,['--timeout seconds', 'Timeout for sending data file to mascot in seconds'])

exit unless search_tool.check_options

if ( ARGV[0].nil? && search_tool.download_only.nil?)
    puts "You must supply an input file"
    puts search_tool.download_only
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

cookie=""
openurlcookie=""

if ( search_tool.use_security)
    $genv.log("Logging in",:info)
    cookie = login(mascot_cgi,search_tool.username,search_tool.mascot_password)
    openurlcookie = "MASCOT_SESSION=#{cookie['MASCOT_SESSION']}; MASCOT_USERID=#{cookie['MASCOT_USERID']}; MASCOT_USERNAME=#{cookie['MASCOT_USERNAME']}"
end

if ( !search_tool.download_only.nil?)
    parts=search_tool.download_only.split("/")
    throw "Must provide a path of the format date/filename" unless parts.length==2
    results_date=parts[0]
    results_file=parts[1]
    download_datfile mascot_cgi, results_date, results_file,search_tool.explicit_output,openurlcookie
else
    #$genv.log("Var mods #{search_tool.var_mods} and fixed #{search_tool.fix_mods}",:info)

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
    else (search_tool.export_format=="mascotdat")
        # Search for the location of the mascot data file in the response
        results=/master_results_?2?\.pl\?file=\.*\/data\/(.*)\/(.+\.dat)/.match(search_response)
        results_date=results[1]
        results_file=results[2]

        download_datfile mascot_cgi, results_date, results_file,search_tool.explicit_output,openurlcookie
    end
    # else
    #     results=/master_results_?2?\.pl\?file=(\.*\/data\/.*\/.+\.dat)/.match(search_response)
    #     results_file = results[1]
    #     export_results mascot_cgi,cookie,results_file,search_tool.export_format, openurlcookie
    # #    export_results mascot_cgi,cookie,results_file,search_tool.export_format
    # end
end


