require 'rubygems'
require 'spreadsheet'


class BioToolsExcelConverter 
  
  def initialize(filename)
    @inputBook = Spreadsheet.open File.new("#{filename}")
  end
  
  def self.isBiotools(filename)
    testBook = Spreadsheet.open File.new("#{filename}")
    testSheet = testBook.worksheet 0
    
    isbiotools=FALSE
    testSheet.each do |row|
      if  (row[0].class==String) && row[0].match(/Digest Matches.*?Score:\s(.*)\)/)   
        isbiotools=TRUE
      end
    end
    
    
    isbiotools
  end
  
  def get_rows
    
    sheet=@inputBook.worksheet 0
    
    protein_rows=[]

    n_rows=sheet.dimensions[1]

    protein_rows=(0...n_rows).collect do |row_i|      
      new_row=nil
      
      row=sheet.row row_i      
      if ( row[0]!=nil)
        digmatch=row[0].match(/Digest Matches.*?Score:\s(.*)\)/)
        if  ( digmatch!=nil )
          new_row=[]          
          text= sheet.row(row_i-1)[0] 
          m=text.match(/\s(\S*)\s*$/)
          throw "Badly formed protein line in biotools file ... could not parse protein name from #{text}" unless m!=nil
          new_row[0]=m[1]
          new_row[1]=digmatch[1]
        end
      end
      
      new_row
    end
    
    protein_rows.compact!
    protein_rows.insert(0,["Accession","Ion Scores"])
    
    protein_rows
    
  end
  
end