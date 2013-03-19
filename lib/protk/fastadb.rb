require 'protk/constants'
require 'bio'

#
# Warning: Uses Bio::Command which is a private API of the Bio package
#

class FastaDB

  def initialize(blast_database_file_path)
    env = Constants.new
    @database = blast_database_file_path
    @makedbcmd = env.makeblastdb
    @searchdbcmd = env.searchblastdb
  end

  def self.create(blast_database_file_path,input_fasta_filepath,type='nucl')
    db = FastaDB.new(blast_database_file_path)
    db.make_index(input_fasta_filepath,type)
    db
  end

  def get_by_id(entry_id)
    fetch(entry_id).shift
  end

  def make_index(input_fasta,dbtype)
    cmd = [ @makedbcmd, '-in', input_fasta, '-parse_seqids','-out',@database,'-dbtype',dbtype]
    res = Bio::Command.call_command(cmd) do |io|
      puts io.read
    end
  end

  def fetch(list)
    if list.respond_to?(:join)
      entry_id = list.join(",")
    else
      entry_id = list
    end

    cmd = [ @searchdbcmd, '-db', @database, '-entry', entry_id ]
    Bio::Command.call_command(cmd) do |io|
      io.close_write
      Bio::FlatFile.new(Bio::FastaFormat, io).to_a
    end
  end

end
