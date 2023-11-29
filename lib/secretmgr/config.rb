require 'pathname'
require 'yaml'

module Secretmgr
  class Config
  	def initialize(parent_pn, format_filename = "format.txt")
  	  	  format_pn = parent_pn + format_filename
  	  	  file_content = File.read(format_pn)
  	  	  @hash = YAML.safe_load(file_content)
  	end
  	  
  	def file_format(*keys)
  	  	result = keys.flatten.each_with_object( [@hash] ){ |item, memo|
	  	  p "file_format item=#{item}"
  	  	  hash = memo[0]
  	  	  memo[0] = hash ? 
  	  	  	(hash.instance_of?(Hash) ? hash[item] : nil) 
  	  	  	: nil
	  	  p "file_format memo=#{memo}"
	  	}
	  	p "file_format @hash=#{@hash}"
	  	p "file_format result=#{result}"
  	  	result ? ( result[0] ? result[0] : @hash["default"] ) : @hash["default"]
  	end
  	
  	def get_file_path(parent_dir_pn, *keys)
  		flat_keys = keys.flatten
  		valid_keys = flat_keys.select{ |key| key != nil }
  		file_format = file_format(valid_keys)
  		case file_format
  		when "JSON_FILE"
  			flat_keys.unshift("JSON_FILE")
  			flat_keys.push("config.json")
  		when "YAML"
  			flat_keys = ["secret.yml"]
  		else
  			#
  		end
  		p "get_file_path flat_keys=#{flat_keys}"
  		array = flat_keys.each_with_object([parent_dir_pn]){ |item, memo|
  				memo[0] = memo[0] + item if item
  		}	
		file = array[0]
		file_pn = Pathname.new(file)
		p "get_file_path: #{file_pn.to_s} #{ file_pn.exist? }"
		
		file
  	end
  end
end
