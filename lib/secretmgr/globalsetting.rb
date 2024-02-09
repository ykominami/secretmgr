module Secretmgr
  class Globalsetting
    require "yaml"
    require "pathname"

    def initialize(file_pn)
      @file_pn = file_pn
      @obj = nil
    end

    def ensure
      File.write(@file_pn, "") unless @file_pn.exist?
    end

    def load
      content = File.read(@file_pn)
      @obj = YAML.safe_load(content)
      @load ||= {}
    end

    def save
      content = YAML.dump(@obj)
      File.write(@file_pn, content)
      Loggerxs.debug "Globalsetting.save @file_pn=#{@file_pn}|"
      Loggerxs.debug "Globalsetting.save content=#{content}|"
    end

    def get(key)
      case key
      when "default_public_keyfile_pn", "default_private_keyfile_pn"
        Pathname.new(@obj[key])
      else
        @obj[key]
      end
    end

    def set(key, value)
      @obj[key] = case key
                  when "default_public_keyfile_pn", "default_private_keyfile_pn"
                    value.to_s
                  else
                    value
                  end
    end
  end
end
