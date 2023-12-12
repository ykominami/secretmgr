# frozen_string_literal: true

require "pathname"
require "yaml"

module Secretmgr
  class Config
    def initialize(parent_pn, format_filename = "format.txt")
      format_pn = parent_pn + format_filename
      file_content = File.read(format_pn)
      @hash = YAML.safe_load(file_content)
    end

    def file_format(*keys)
      result = keys.flatten.each_with_object([@hash]) do |item, memo|
        hash = memo[0]
        memo[0] = if hash
                    (hash.instance_of?(Hash) ? hash[item] : nil)
                  end
      end
      result ? (result[0] || @hash["default"]) : @hash["default"]
    end

    def get_file_path(parent_dir_pn, *keys)
      flat_keys = keys.flatten
      valid_keys = flat_keys.compact
      file_format = file_format(valid_keys)
      case file_format
      when "JSON_FILE"
        flat_keys.unshift("JSON_FILE")
        flat_keys.push("config.json")
      when "YAML"
        flat_keys = ["secret.yml"]
      end
      array = flat_keys.each_with_object([parent_dir_pn]) do |item, memo|
        memo[0] = memo[0] + item if item
      end
      array[0]
    end
  end
end
