#!/usr/bin/env ruby
#
# This file is part of protk
# Created by Ira Cooke 18/1/2011
#
# Converts an Excel Spreadsheet to a tab delimited table
#
#

require 'protk/constants'
require 'protk/command_runner'
require 'protk/tool'
require 'spreadsheet'

# Setup command-line options for this tool. 
#
tool=Tool.new({:explicit_output=>true})
tool.option_parser.banner = "Convert an xls file to a tab delimited table.\n\nUsage: xls_to_table.rb [options] file1.xls"

tool.option_parser.parse!

input_file=ARGV[0]

output_file=tool.explicit_output
output_file="#{input_file}.csv" unless ( output_file != nil )

output_fh = File.new(output_file,'w')


# Open the original excel workbook for reading
Spreadsheet.client_encoding = 'UTF-8'   
inputBook = Spreadsheet.open "#{input_file}"
inputSheet = inputBook.worksheet 0

inputSheet.each do |row|
  line=""
  row.each do |colv| 
    line << "#{colv}\t" 
  end
  line.chop!
  output_fh.write "#{line}\n"
end

output_fh.close


