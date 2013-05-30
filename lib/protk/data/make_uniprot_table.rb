#!/usr/bin/env ruby

file_name = ARGV[0]

out_fh = File.new("uniprot_accessions.loc",'w')

File.foreach(file_name) { |line|  
	cols= line.chomp.split("\t")
	if ( cols[2]!="from" )
		db_key = "#{cols[0].gsub(" ","_").downcase}_"
		out_fh.write "#{cols[0]}\t#{db_key}\t#{cols[1]}\t#{db_key}\n"
	end
}

out_fh.close



out_fh = File.new("uniprot_input_accessions.loc",'w')

File.foreach(file_name) { |line|  
	cols= line.chomp.split("\t")
	if ( cols[2]!="to" )
		db_key = "#{cols[0].gsub(" ","_").downcase}_"
		out_fh.write "#{cols[0]}\t#{db_key}\t#{cols[1]}\t#{db_key}\n"
	end
}

out_fh.close
