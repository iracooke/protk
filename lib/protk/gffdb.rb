require 'protk/constants'
require 'bio'


class GFFDB

  attr_accessor :id_to_records_map

  def initialize(gff_file_path)
    @database = gff_file_path
    @id_to_records_map={}
    @id_to_cds_map={}
  end

  def self.create(gff_file_path)
    db = GFFDB.new(gff_file_path)
    db.make_index(gff_file_path)
    db
  end

  def get_by_id(entry_id)
    @id_to_records_map[entry_id]
  end

  def get_cds_by_parent_id(entry_id)
    @id_to_cds_map[entry_id]
  end


  def make_index(input_gff)
    io = File.open(input_gff, "r")
    gffdb = Bio::GFF::GFF3.new(io)  #parses the entire db

    # Now create the mapping from ids to records
    gffdb.records.each do |record| 

      @id_to_records_map[record.id] = [] if @id_to_records_map[record.id].nil?
      @id_to_records_map[record.id] << record

      begin
        # puts record.feature_type.match(/CDS/)
        if record.feature_type.to_s =~ /CDS/i
          # puts record.feature_type
          parent_id=record.attributes_to_hash['Parent']
          # puts parent_id
          if parent_id
            @id_to_cds_map[parent_id] = [] if @id_to_cds_map[parent_id].nil?
            @id_to_cds_map[parent_id] << record
          end
        end

      rescue
        puts "Problem initializing cds map for #{record}"
      end
    end

  end

end