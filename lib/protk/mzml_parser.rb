require 'libxml'

include LibXML

class MzMLParser < Object


	def initialize(path)
		@namespace=
		@mzml_ns_prefix="xmlns:"
		@mzml_ns="xmlns:http://psi.hupo.org/ms/mzml"

		doc=XML::Document.file(path)
		@file_reader=XML::Reader.document(doc)
	end

	def next_runid()
		until @file_reader.name=="run" 
			if !@file_reader.read()
				return nil
			end
		end
		return @file_reader.get_attribute('id')
	end

	def next_spectrum()

		until @file_reader.name=="spectrum" 
			if !@file_reader.read()
				return nil
			end
		end

		this_spect=spectrum_as_hash(@file_reader.expand)

		@file_reader.next_sibling

		return this_spect
	end

	def spectrum_as_hash(spectrum)
		index=spectrum.attributes['index']
		sid = spectrum.attributes['id']
		precursor_mz_param = spectrum.find(".//#{@mzml_ns_prefix}cvParam[@accession=\"MS:1000744\"]",@mzml_ns)[0]
		mslevel_param = spectrum.find("./#{@mzml_ns_prefix}cvParam[@accession=\"MS:1000511\"]",@mzml_ns)[0]

		title_param = spectrum.find("./#{@mzml_ns_prefix}cvParam[@accession=\"MS:1000796\"]",@mzml_ns)[0]

		# prec_mz = spectrum.find(".//#{@mz}")

		precursor_mz_mz = precursor_mz_param.attributes['value'] if precursor_mz_param
		mslevel = mslevel_param.attributes['value'] if mslevel_param
		spectrum_title = title_param['value'] if title_param

		data_arrays = spectrum.find("./#{@mzml_ns_prefix}binaryDataArrayList/#{@mzml_ns_prefix}binaryDataArray",@mzml_ns)

		data={}
		data_arrays.each do |arr|
			the_data = arr.find("./#{@mzml_ns_prefix}binary",@mzml_ns)[0].content
			mzaccession = arr.find("./#{@mzml_ns_prefix}cvParam[@accession=\"MS:1000514\"]",@mzml_ns)
			if ( mzaccession.length==1 )
				data[:mz] = the_data
			else 
				data[:intensity] = the_data
			end
		end
		data[:title]=spectrum_title
		data[:mzlevel]=mslevel
		data[:index]=index
		data[:precursormz]=precursor_mz_mz
		data[:id]=sid

		data
	end

end