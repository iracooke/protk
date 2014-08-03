require 'protk/constants'
require 'bio'


class GFFDB

  attr_accessor :id_to_records_map

  def initialize(gff_file_path)
    env = Constants.new
    @database = gff_file_path
    @id_to_records_map={}
  end

  def self.create(gff_file_path)
    db = GFFDB.new(gff_file_path)
    db.make_index(gff_file_path)
    db
  end

  def get_by_id(entry_id)
    @id_to_records_map[entry_id]
  end

  def make_index(input_gff)
    io = File.open(input_gff, "r")
    gffdb = Bio::GFF::GFF3.new(io)  #parses the entire db

    # Now create the mapping from genes to arrays of records
    gffdb.records.each do |record| 

      # Initialize array of records for this id if needed
      @id_to_records_map[record.id]=[] unless @id_to_records_map.has_key? record.id

      @id_to_records_map[record.id] << record

    end

  end

end