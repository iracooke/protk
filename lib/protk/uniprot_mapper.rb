require 'rubygems'
require 'net/http'
require 'protk/constants'

# Provides access to uniprot.org via its API
# See docs and examples here http://www.uniprot.org/faq/28#id_mapping_examples
#
class UniprotMapper

  def initialize
    @genv = Constants.new
  end

  def map(from_id_type,from_ids,output_id)

    from_query = from_ids.join(" ")

    base = 'www.uniprot.org'
    tool = 'mapping'
    params = {
      'from' => from_id_type, 'to' => output_id, 'format' => 'tab',
      'query' => from_query
    }

    http = Net::HTTP.new base
    @genv.log "Mapping to #{output_id}" ,:info
    response = http.request_post '/' + tool + '/',
    params.keys.map {|key| key + '=' + params[key]}.join('&')

    loc = nil
    while response.code == '302'
      loc = response['Location']
      response = http.request_get loc
    end

    while loc
      wait = response['Retry-After'] or break
      @genv.log "Waiting (#{wait})..." , :info
      sleep wait.to_i
      response = http.request_get loc
    end

    response.value # raises http error if not 2xx
    return response.body
  end

end