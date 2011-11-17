# Code for interacting with EuPathDB gene information files e.g. http://cryptodb.org/common/downloads/release-4.3/Cmuris/txt/CmurisGene_CryptoDB-4.3.txt
# These gene information files contain a large amount of information about individual genes/proteins in EuPathDBs.

require 'tempfile'

# A class for extracting gene info from a particular gene from the information file
class EuPathDBGeneInformationFileExtractor
  # A filename path to the gene information file
  attr_accessor :filename
  
  def initialize(filename = nil)
    @filename = filename
  end
  
  # Returns a EuPathDBGeneInformation object corresponding to the wanted key. If
  # there are multiple in the file, only the first is returned. If none are found, nil is returned.
  #
  # If grep_hack_lines is defined (as an integer), then a shortcut is applied to speed things up. Before parsing the gene info file, grep some lines after the "Gene Id: .." line. Then feed that into the parser. 
  def extract_gene_info(wanted_gene_id, grep_hack_lines = nil)
    inside_iterator = lambda do |gene|
      return gene if wanted_gene_id == gene.info['Gene Id']
    end
    
    filename = @filename
    p @filename
    if grep_hack_lines and grep_hack_lines.to_i != 0
      tempfile=Tempfile.new('reubypathdb_grep_hack')
      # grep however many lines from past the point. Rather dodgy, but faster.
      raise Exception, "grep_hack_lines should be an integer" unless grep_hack_lines.is_a?(Integer)
      `grep -A #{grep_hack_lines} 'Gene Id: #{wanted_gene_id}' '#{@filename}' >#{tempfile.path}`
      EuPathDBGeneInformationTable.new(File.open(tempfile.path)).each do |gene|
        return inside_iterator.call(gene)
      end
    else
      # no grep hack. Parse the whole gene information file
      EuPathDBGeneInformationTable.new(File.open(@filename)).each do |gene|
        return inside_iterator.call(gene)
      end
    end
    return nil
  end
end

# A class for parsing the 'gene information table' files from EuPathDB, such
# as http://cryptodb.org/common/downloads/release-4.3/Cmuris/txt/CmurisGene_CryptoDB-4.3.txt
#
# The usual way of interacting with these is the use of the each method, 
# which returns a EuPathDBGeneInformation object with all of the recorded
# information in it.
class EuPathDBGeneInformationTable
  include Enumerable
  
  # Initialise using an IO object, say File.open('/path/to/CmurisGene_CryptoDB-4.3.txt'). After opening, the #each method can be used to iterate over the genes that are present in the file
  def initialize(io)
    @io = io
  end
  
  # Return a EuPathDBGeneInformation object with
  # the contained info in it, one at a time
  def each
    while g = next_gene
      yield g
    end
  end
  
  # Returns a EuPathDBGeneInformation object with all the data you could
  # possibly want.
  def next_gene
    info = EuPathDBGeneInformation.new
    
    # first, read the table, which should start with the ID column
    line = @io.readline.strip
    while line == ''
      return nil if @io.eof?
      line = @io.readline.strip
    end
    
    while line != ''
      if matches = line.match(/^(.*?)\: (.*)$/)
        info.add_information(matches[1], matches[2])
      else
        raise Exception, "EuPathDBGeneInformationTable Couldn't parse this line: #{line}"
      end
      
      line = @io.readline.strip
    end
    
    # now read each of the tables, which should start with the
    # 'TABLE: <name>' entry
    line = @io.readline.strip
    table_name = nil
    headers = nil
    data = []
    while line != '------------------------------------------------------------'
      if line == ''
        # add it to the stack unless we are just starting out
        info.add_table(table_name, headers, data) unless table_name.nil?
        
        # reset things
        table_name = nil
        headers = nil
        data = []
      elsif matches = line.match(/^TABLE\: (.*)$/)
        # name of a table
        table_name = matches[1]
      elsif line.match(/^\[.*\]/)
        # headings of the table
        headers = line.split("\t").collect do |header|
          header.gsub(/^\[/,'').gsub(/\]$/,'')
        end
      else
        # a proper data row
        data.push line.split("\t")
      end
      line = @io.readline.strip      
    end
            
    # return the object that has been created
    return info
  end
end

# Each gene in the gene information table is represented
# by 2 types of information - info and tables.
# info are 1 line data, whereas tables are tables of
# data with possibly multiple rows
class EuPathDBGeneInformation
  def info
    @info
  end
  
  def get_info(key)
    @info[key]
  end
  alias_method :[], :get_info
  
  def get_table(table_name)
    @tables[table_name]
  end
  
  def add_information(key, value)
    @info ||= {}
    @info[key] = value
    "Added info #{key}, now is #{@info[key]}"
  end
  
  def add_table(name, headers, data)
    @tables ||= {}
    @tables[name] = []
    data.each do |row|
      final = {}
      row.each_with_index do |cell, i|
        final[headers[i]] = cell
      end
      @tables[name].push final
    end
  end
end
