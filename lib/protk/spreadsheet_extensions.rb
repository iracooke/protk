require 'spreadsheet'
# Add a method to the Spreadsheet::Worksheet class to insert a column
class Spreadsheet::Worksheet < Object
    def insert_column(col,index)
      # First check to see if the length of the column equals the number of rows
      if ( col.length!=self.rows.length && self.rows.length!=0)
        raise "The length of column #{col.length} does not equal the number of rows #{self.rows.length}"
      end
      if ( col.class!=Array || index.class!=Fixnum)
        raise "Wrong arguments. Requires a column array and an integer index"
      end
      
      # Check for special case where there are no rows yet and if so then insert as new rows
      if ( self.rows.length==0)
        col.each_index { |i|
          self.insert_row(i,[col[i]])        
        }
      else
        # Insert the column row by row. Probably inefficient but it works
        rowi=0
        self.each {|row|
          row.insert(index,col[rowi])        
          rowi+=1
        }
      end
    end
  end
  
  class Spreadsheet::Workbook < Object
    
    
    # creates an output excel file (returning the workbook object), transcribing all original content up to the given number of rows
    # Throws an error if the input contains more than 1 worksheet
    #
    def copyBook(numrows=0)
     
     if ( !numrows )
       numrows=0
     end
     
      # Create a new workbook from scratch for writing
      outputBook = Spreadsheet::Workbook.new
      outputSheet = outputBook.create_worksheet

      # There should only be one worksheet in the input workbook
      worksheets=self.worksheets
      if ( self.worksheets.length != 1 )
        puts "More than one worksheet in this excel file. This script only operates on single worksheets"
      end

      # Get the worksheet  
      inputSheet=self.worksheet 0

      # Figure out how many rows to convert if not specified
      if ( numrows==0 || numrows > (inputSheet.row_count+1))
        numrows=inputSheet.row_count
      end


      # Transcribe everything from the old worksheet to the new one
      puts "Creating new spreadsheet with #{numrows} rows"
      (0...[numrows,inputSheet.row_count].min).each { |r| 

        outputSheet.insert_row(r,inputSheet.row(r))

        newRow=outputSheet.row(r)

        # After inserting the row make sure it doesn't contain any nil values
        newRow.each_index { |ci| 
          if ( newRow[ci]==nil)
            newRow[ci]=""
          end
        }      
      }
      outputBook
    end
    
    
end
