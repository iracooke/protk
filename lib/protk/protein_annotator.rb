require 'rubygems'
require 'spreadsheet'
require 'protk/swissprot_database'
require 'protk/bio_sptr_extensions'
require 'protk/protxml'
require 'protk/spreadsheet_extensions'
require 'protk/biotools_excel_converter'
require 'protk/plasmodb'
require 'protk/constants'


class ProteinAnnotator < Object


  def initialize()
      @genv = Constants.new()
  end
  
  def env
    return @genv
  end
  
  def outputBookFromExcelInput(inputFile,numrows=0)
    
     # Open the original excel workbook for reading
     inputBook = Spreadsheet.open "#{inputFile}"

     return inputBook.copyBook(numrows)

  end
  
  
  
  # Combines results from prot and pep xml files
  # 
  def outputBookFromProtXMLAndPepXML(inputFileProt,inputFilePep,numrows=0)
    protxml=ProtXML.new(inputFileProt)

    # By default here we don't report anything with a probability less than 0.6
    # This should be a user parameter someday
    #
    rows=protxml.as_rows(0.6) 

    # Figure out how many rows to convert if not specified
    #
    if ( numrows==0 || numrows >= rows.length)
      numrows=rows.length
    else
      rows=rows[0...numrows]
    end



    # Create a new workbook from scratch for writing
    outputBook = Spreadsheet::Workbook.new
    outputSheet = outputBook.create_worksheet

    rows.reverse!

    rows.each { |row| 
      outputSheet.insert_row(0,row)
    }
        
    outputBook
  end
  
  
  
  
  # Takes a prot.xml file as input and returns an excel workbook with a single column containing the Accessions of proteins in the file
  # The header of the accessions column will be 'Accessions'
  # If a protein has 'indistinguishable proteins' each of those is given a separate line
  #
  # Throws an error if no proteins could be found in the prot.xml file
  # In addition to the Accessions column, other information will be extracted from the file including
  # 1. A list of indistinguishable proteins
  # 2. The number of peptides on which the ID was based
  # 3. The protein probability
  # 4. A ; separated list of peptides on which the ID is based
  # 5. Percent coverage for the protein
  # 
  def outputBookFromProtXML(inputFile,numrows=0)
    protxml=ProtXML.new(inputFile)

    # By default here we don't report anything with a probability less than 0.6
    # This should be a user parameter someday
    #
    rows=protxml.as_rows(0.6) 

    # Figure out how many rows to convert if not specified
    #
    if ( numrows==0 || numrows>=rows.length)
      numrows=rows.length
    else
      rows=rows[0...numrows]
    end



    # Create a new workbook from scratch for writing
    outputBook = Spreadsheet::Workbook.new
    outputSheet = outputBook.create_worksheet

    rows.reverse!

    rows.each { |row| 
      outputSheet.insert_row(0,row)
    }
        
    outputBook
  end
  
  
  
  
  
  
  
  # Takes a biotools outputted excel file and produces an excel workbook with a single Accessions column of proteins
  #
  def outputBookFromBiotoolsExcel(inputFile,numrows=0)
    converter=BioToolsExcelConverter.new(inputFile)
    rows=converter.get_rows
        
    # Create a new workbook from scratch for writing
    outputBook = Spreadsheet::Workbook.new
    outputSheet = outputBook.create_worksheet

    rows.reverse!

    rows.each { |row| 
      outputSheet.insert_row(0,row)
    }
        
    outputBook
    
    
  end
  
  # Takes a WarpLC Protein List file as input and returns an excel workbook with a single column containing the Accessions of proteins in the file
  # The header of the accessions column will be 'Accessions'
  # Throws an error if no proteins could be found in the WarpLC file .. this could also happen if the file is the wrong format
  # 
  def outputBookFromWarpLCInput(inputFile,numrows=0)
    file=File.new(inputFile)
    xmldoc=REXML::Document.new(file)
    accessions=REXML::XPath.match(xmldoc,"//ProteinReport/Protein")
    if ( accessions==nil )
      throw "No proteins found in the WarpLC Proteinlist file #{inputFile}"
    end
    accessions=accessions.collect { |el| el.attributes['Accession']}
    accessions.insert(0,"Accession")

    # Figure out how many rows to convert if not specified
    if ( numrows==0 || numrows>accessions.length)
      numrows=accessions.length+1
    else
      accessions=accessions[0...numrows]
    end



    # Create a new workbook from scratch for writing
    outputBook = Spreadsheet::Workbook.new
    outputSheet = outputBook.create_worksheet

    outputSheet.insert_column(accessions,0)
    
    outputBook
  end
  
  # First looks at the file extension. If it is xls then filetype 'xls' is returned. 
  # Otherwise, we assume the file is XML
  #
  def isExcelFile(fileName,input_type)
    if ( input_type=="excel")
      return true
    end
    
    ext=fileName.split(".").last
    if(ext=="xls")
      return true
    end
    return false
  end
  
  def isProtXMLFile(fileName,input_type)
    if ( input_type=="protXML")
      return true
    end
    
    
    if ( fileName.match(/\.prot\.xml$/) != nil )
      return true
    else
      return false
    end
  end
  
  def isBioToolsFile(fileName,input_type)    
    BioToolsExcelConverter.isBiotools(fileName)
  end
  
  # Given a worksheet with a column called 'Status' change true values to 'Validated' and false values to 'Potential'
  def renameValuesInColumn(workSheet,colIndex,from,to)
    workSheet.rows.each { |row| 
      if ( row[colIndex]==from)
        row[colIndex]=to
      end
    }
  end
  
  def hasAccession(row)
    hasit=false
    row.each do|cell|
      if (cell.to_s=="Accession")
        hasit=true
      end
    end
    hasit
  end
  
  def row_is_empty(row)
    isempty=true
    if (row==nil)
      return true
    end
    
    row.each do |cell|
      if ( cell!=nil && cell.to_s!="")
        isempty=false
      end
    end
    isempty
  end
  
  def convert(inputFile,outputFile,input_type=nil,output_type="xls",numrows=0,accessionColumnName="Accession",entrezIDColumnName="Entrez.ID",hiddenColumns=[])

    @genv.log("Converting #{inputFile} to #{outputFile}",:info)

    Spreadsheet.client_encoding = 'UTF-8'   
    
    
    case true
    when isExcelFile(inputFile,input_type)
      @genv.log("Excel file was biotools",:info)      
      if ( isBioToolsFile(inputFile,input_type))
        outputBook=outputBookFromBiotoolsExcel(inputFile,numrows)
      else
        @genv.log("Excel file was non biotools",:info)
        outputBook=outputBookFromExcelInput(inputFile,numrows)
      end
      outputSheet=outputBook.worksheet 0
    when isProtXMLFile(inputFile,input_type)
      @genv.log("Got a Prot XML File as Input",:info)
      outputBook=outputBookFromProtXML(inputFile,numrows)
      outputSheet=outputBook.worksheet 0      
    else      
      @genv.log("File is not prot.xml or excel .. trying WarpLCResult",:info)
      outputBook=outputBookFromWarpLCInput(inputFile,numrows)
      outputSheet=outputBook.worksheet 0
    end
    
    # Chop off and save any rows prior to the header and remove any empty rows
    #
    rows_for_deletion=[]
    header_row=nil
    keep_rows=[]
    rowi=0
    outputSheet.each do |row|
      
      if ( !row_is_empty(row) && header_row==nil && hasAccession(row))
        header_row=rowi
      end

      if (row_is_empty(row) || header_row==nil)
        rows_for_deletion.push(rowi)
      end
      
      if (header_row==nil)
        keep_rows.push(row)
      end
      rowi=rowi+1
    end
        
    deletion_index=0
    rows_for_deletion.each do |i|
      outputSheet.delete_row(i-deletion_index)
      deletion_index=deletion_index+1
    end    
    
    header=outputSheet.row 0
    lastcolIndex=0
    accessionColumn=nil

    # Grab the accession column
    for i in 0...header.length
      if ( header[i]==accessionColumnName)
        accessionColumn=outputSheet.column i
        accessionColumnIndex=i
      end
      if ( header[i]=="" && lastcolIndex==0)
        lastcolIndex=i
      end

      if ( header[i]=="OK")
        header[i]="Status"
        renameValuesInColumn(outputSheet,i,"true","Validated")
        renameValuesInColumn(outputSheet,i,"false","Contaminant")
      end
      
    end

    # If we didn't find an empty column then just set lastcolIndex to i
    if ( lastcolIndex==0)
      lastcolIndex=i
    end
    
    if ( accessionColumn==nil) 
      throw "No Accession column in input excel file. One column must have the header 'Accession'"
    end
    
    ids = accessionColumn.collect { |id| 
      if ( id!=nil)
        id
      else
        ""
      end
    }
    # Remove the 0th value because it is the header
    ids.delete_at(0)

    #### Now grab some additional column information from uniprot ####

    # Create a Hash with keys corresponding to the keys returned by uniprot.parse and with values corresponding to arrays of column values
    # We start the columns off with the header name
    newColumns={'recname'=>["Primary Name"],'cd'=>["CD Antigen Name"],'altnames'=>["Alternate Names"], 
      'location' => ["Subcellular Location"],
      'function' => ["Known Function"],
      'similarity' => ["Similarity"],
      'tissues' => ["Tissue Specificity"],
      'disease' => ["Disease Association"],
      'domain' => ["Domain"],
      'subunit' => ["Sub Unit"],
      'nextbio' => ["NextBio"],
      'ipi' => ["IPI"],
      'intact' => ["Interactions"],
      'pride' => ['Pride'],
      'ensembl'=> ['Ensembl'],
      'num_transmem'=>["Transmembrane Regions"],
      'signalp'=>['Signal Peptide']
    }

    newColumnKeys=['recname','cd','altnames','location','function','similarity','tissues','disease','domain','subunit','nextbio','ipi','intact','pride','ensembl','num_transmem','signalp']


    #    xmlurls=accs.collect {|acc| uniprot.entry_url_for_accession(acc,'xml') }

    @genv.log("Initializing database",:info)

    swissprotdb=SwissprotDatabase.new(@genv)
    @genv.log("Retrieving data for #{ids.length} entries from Swissprot database ",:info)
    accs=[]
    plasmodbids=[]
    found_plasmodb_ids=false
    
    $stdout.putc "\n"
    ids.each { |uniprot_id| 

      $stdout.putc "."
      $stdout.flush

      sptr_entry=swissprotdb.get_entry_for_name(uniprot_id)


      if ( sptr_entry==nil)
        @genv.log("No entry for #{uniprot_id} in uniprot database",:warn)
        newColumnKeys.each { |key| newColumns[key].push("") }
        accs.push("")
        
        # Bit of a hack. If the id is not sp and not decoy we assume it is plasmodb
        #
        if ( uniprot_id=~/^decoy_/)
        else
          plasmodbids.push(uniprot_id)
          found_plasmodb_ids=true 
        end
        
      else
        accs.push(sptr_entry.accession)
        plasmodbids.push("")
        
        newColumnKeys.each { |key|     
            
          val=sptr_entry.send(key)
          if ( val==nil)
            str=""
          elsif ( val.class==Array)
            str=val.join(";")
          else
            str=val.to_s
          end
          newColumns[key].push(str)
        }
      end
    }
    $stdout.putc "\n"
    
    
    # Trying PlasmoDB for unknown IDs
    #
    if ( found_plasmodb_ids  ) 
      $stdout.putc "Searching PlasmoDB for unknown Id's\n"
      @genv.log "Searching PlasmoDB for unknown Id's", :info

      plasmodb = PlasmoDB.new(@genv)

      row_index=1 # Starts from 1 because of the header
      
      plasmodbids.each { |plasmodb_id| 
        
        if ( plasmodb_id!="")
          p plasmodb_id
        
          plasmodb_entry = plasmodb.get_entry_for_name(plasmodb_id)
        
          if ( plasmodb_entry != nil )

#             newColumnKeys=['recname','cd','altnames','location','function','similarity','tissues','disease','domain','subunit','nextbio','ipi','intact','pride','ensembl','num_transmem','signalp']

            newColumns['recname'][row_index]=plasmodb_entry['Product Description']
            
            if ( plasmodb_entry['Annotated GO Component']!="null" )
              newColumns['location'][row_index]=plasmodb_entry['Annotated GO Component']
            else 
              newColumns['location'][row_index]=plasmodb_entry['Predicted GO Component']
            end
            
            if ( plasmodb_entry['Annotated GO Function'] !="null" )
              newColumns['function'][row_index]=plasmodb_entry['Annotated GO Function']
            else
              newColumns['function'][row_index]=plasmodb_entry['Predicted GO Function']              
            end
            
            newColumns['signalp'][row_index]=plasmodb_entry['SignalP Peptide']
            
            newColumns['num_transmem'][row_index] = plasmodb_entry['# TM Domains']

          end
        end

        row_index=row_index+1

        
      }
      
      
    end
    
    
    @genv.log("Done",:info)
    
    newColumnKeys.reverse.each { |key| 
      outputSheet.insert_column(newColumns[key],lastcolIndex)
    }

    # Now hide some columns
    hide=hiddenColumns
    for i in 0...outputSheet.row(0).length
      if ( hide.detect { |h| header[i].include?(h)} !=nil)
        outputSheet.column(i).hidden=TRUE
        accessionColumn=outputSheet.column i
        accessionColumnIndex=i
      end
      if ( header[i]=="" && lastcolIndex==0)
        lastcolIndex=i
      end
    end


    # Now add hyperlinks to various columns
    @genv.log("Creating Hyperlinks",:info)

    # Figure out column indexes for all the hyperlinked columns
    header=outputSheet.row 0
    
    entrezIDColumn=nil
    
    
    # Grab the column indexes of existing columns to be hyperlinked
    for i in 0...header.length
      if ( header[i]==accessionColumnName )
        accessionColumnIndex=i
      end
      if ( header[i]=="IPI")
        ipiColumnIndex=i
      end
      if ( header[i]=="Interactions")
        intactColumnIndex=i
      end
      if ( header[i]=="Pride")
        prideColumnIndex=i
      end
      if ( header[i]=="Ensembl")
        ensemblColumnIndex=i
      end
      if ( header[i]=="NextBio")
        nextbioColumnIndex=i
      end
      
      if (header[i]==entrezIDColumnName)
        entrezIDColumnIndex=i
        entrezIDColumn=outputSheet.column i
        entrezIDs=entrezIDColumn.collect { |id| id }
      end
      
    end


    # Create a format for the hyperlinks
    hyperlink_format = Spreadsheet::Format.new({:color => :blue,:weight => :bold,:size => 10})

    # Add hyperlink format to the appropriate columns
    outputSheet.column(accessionColumnIndex).default_format=hyperlink_format
    outputSheet.column(nextbioColumnIndex).default_format=hyperlink_format
    outputSheet.column(ipiColumnIndex).default_format=hyperlink_format
    outputSheet.column(intactColumnIndex).default_format=hyperlink_format
    outputSheet.column(prideColumnIndex).default_format=hyperlink_format
    outputSheet.column(ensemblColumnIndex).default_format=hyperlink_format

    if ( entrezIDColumn!=nil)
      outputSheet.column(entrezIDColumnIndex).default_format=hyperlink_format
    end
    
    # Create all the hyperlinks
    for rowi in 1...outputSheet.rows.length do

      if ( plasmodbids[rowi-1]!="")
        # Assume plasmodb .. and use plasmodb url
        outputSheet.row(rowi)[accessionColumnIndex]=Spreadsheet::Link.new(url="http://www.plasmodb.org/plasmo/showRecord.do?name=GeneRecordClasses.GeneRecordClass&project_id=&primary_key=#{ids[rowi-1]}",description=plasmodbids[rowi-1]) 
      else 
        # Otherwise assume sp
        outputSheet.row(rowi)[accessionColumnIndex]=Spreadsheet::Link.new(url="http://www.uniprot.org/uniprot/#{accs[rowi-1]}.html",description=ids[rowi-1]) 
      end
      
      outputSheet.row(rowi)[nextbioColumnIndex]=Spreadsheet::Link.new(url="http://www.nextbio.com/b/home/home.nb?id=#{newColumns['nextbio'][rowi]}&type=feature",description=newColumns['nextbio'][rowi])
      outputSheet.row(rowi)[ipiColumnIndex]=Spreadsheet::Link.new(url="http://www.ebi.ac.uk/cgi-bin/dbfetch?db=IPI&id=#{newColumns['ipi'][rowi]}",description=newColumns['ipi'][rowi])
      outputSheet.row(rowi)[intactColumnIndex]=Spreadsheet::Link.new(url="http://www.ebi.ac.uk/intact/pages/interactions/interactions.xhtml?query=#{newColumns['intact'][rowi]}*",description=newColumns['intact'][rowi])
      outputSheet.row(rowi)[prideColumnIndex]=Spreadsheet::Link.new(url="http://www.ebi.ac.uk/pride/searchSummary.do?queryTypeSelected=identification%20accession%20number&identificationAccessionNumber=#{newColumns['pride'][rowi]}",description=newColumns['pride'][rowi])
      outputSheet.row(rowi)[ensemblColumnIndex]=Spreadsheet::Link.new(url="http://www.ensembl.org/Homo_sapiens/Transcript/Summary?db=core;t=#{newColumns['ensembl'][rowi]}",description=newColumns['ensembl'][rowi])
      outputSheet.row(rowi).height=24

  
      if ( entrezIDColumn!=nil && entrezIDs[rowi]!=nil)
        outputSheet.row(rowi)[entrezIDColumnIndex]=Spreadsheet::Link.new(url="http://www.ncbi.nlm.nih.gov/gene/#{entrezIDs[rowi].to_i.to_s}",description=entrezIDs[rowi].to_i.to_s)
      end

    end
        
    # Change the names of any columns to nicer values if you need to
    #
    outputSheet.row(0)[accessionColumnIndex]="Uniprot Link"
    
    if ( entrezIDColumn!=nil)
      outputSheet.row(0)[entrezIDColumnIndex]="Entrez.ID"
    end
    
    
    
    # Having hyperlinked existing columns we now add any additional columns (hyperlinks based on existing data)
    # Note that all the column indexes will now be invalid which is why this is done near the end
    #
    
    # Insert an entrez ID based iHOP literature search link if possible
    if ( entrezIDColumn!=nil)
      
      @genv.log("Creating iHOP literature search link",:info)
      
      ihopURLs=entrezIDs.collect do |entrezid| 
        "http://www.ihop-net.org/UniPub/iHOP/in?dbrefs_1=NCBI_GENE__ID|#{entrezid.to_i.to_s}"
      end
      
      columnIndex=ensemblColumnIndex+1
      
      # Insert this column after the ensembl Link (which is before other literature based stuff)
      outputSheet.insert_column(ihopURLs,columnIndex)
      
      # Create the links
      for rowi in 0...outputSheet.rows.length do
        outputSheet.row(rowi)[columnIndex]=Spreadsheet::Link.new(url=ihopURLs[rowi],description=entrezIDs[rowi].to_i.to_s)
      end
      
      # Format the links
      outputSheet.column(columnIndex).default_format=hyperlink_format
      
      # And give the header a proper name
      outputSheet.row(0)[columnIndex]="iHOP literature search"
      
    end
    
    
    @genv.log("Formatting header",:info)

    # Format the Header row
    headerFormat=Spreadsheet::Format.new({ :weight => :bold,:size => 11 })
    outputSheet.row(0).default_format=headerFormat

    # Here we put in a little workaround for a problem with the Spreadsheet gem. 
    # If the text "false" is in a column it will substitute nil for the false value and then fail when attempting to convert nil to an integer. 
    # We workaround by changing the word "true" to "positive" and false to "negative"  
    outputSheet.rows.each { |row|             
      
      row.each_index { |ri|         

        if ( row[ri].class==NilClass)
          p "Encountered a nil value in the sheet converting to empty string"
          row[ri]=""
        end

        if ( row[ri]==true)
          row[ri]="positive"
        elsif (row[ri]==false)
          row[ri]="negative"
        end
      }
      

      
    }    


    # Put the header rows back
    #
    keep_rows.reverse!
    keep_rows.each do |row|
      outputSheet.insert_row(0,row)      
    end



    # Finally write the results
   @genv.log("Writing New Workbook #{outputFile}",:info)
    outputBook.write outputFile
  end

end
