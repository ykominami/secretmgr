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
      # p "@file_pn=#{@file_pn}"
      content = File.read(@file_pn)
      @obj = YAML.safe_load(content)
      @load ||= {}
      # p "Globalsetting.load @obj=#{@obj}|"
    end

    def save
      content = YAML.dump(@obj)
      File.write(@file_pn, content)
      p "Globalsetting.save @file_pn=#{@file_pn}|"
      p "Globalsetting.save content=#{content}|"
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
          # p "Globalsetting.set @obj=#{@obj}|"
        else
          value
        end
    end
  end
end
