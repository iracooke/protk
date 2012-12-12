require 'rubygems'
require 'rexml/document'
require 'rexml/xpath'

class PepXML
  def initialize(file_name)
    @doc=REXML::Document.new(File.new(file_name))
  end

  def find_runs() 
    runs = {}
    REXML::XPath.each(@doc,"//msms_run_summary") do |summary|
      base_name = summary.attributes["base_name"]
      if not runs.has_key?(base_name)
        runs[base_name] = {:base_name => summary.attributes["base_name"],
                           :type => summary.attributes["raw_data"]}
      end
    end
    runs
  end
  
end