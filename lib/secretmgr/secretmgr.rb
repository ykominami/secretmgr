# frozen_string_literal: true

require "pathname"
require "debug"

module Secretmgr
  # 秘匿情報マネージャ
  class Secretmgr
    attr_reader :decrypted_text, :secret

    @init_count = 0
    # @setting_file = "setting.yml"
    JSON_FILE_DIR = "JSON_FILE"
    SETTING_KEY = "key"
    SETTING_IV = "iv"
    FORMAT_JSON = "JSON_FILE"
    FORMAT_YAML = "YAML"
    YML = "yml"
    # @dot_yml = "yml"
    # @secret_dir = "secret"

    class << self
      def log_init(log_level = :info)
        Loggerxs.init("log_", "log.txt", ".", true, log_level) if @init_count.zero?
        @init_count += 1
      end

      def reset_init_count
        @init_count = 0
      end

      def create(secret_dir_pn, public_keyfile_pn, private_keyfile_pn)
        @inst = Secretmgr.new(secret_dir_pn, public_keyfile_pn, private_keyfile_pn)
        @inst.set_setting_for_data(plain_setting_file_pn, plain_secret_file_pn)
        @inst
      end

      # attr_reader :setting_file, :format_file, :ssh_dir, :pem_dir, :no_pass_dir, :no_pass_rsa_dir, :json_file_dir,
      #            :setting_key, :setting_iv, :format_json, :format_yaml, :secret_dir
    end

    def initialize(secret_dir_pn, public_keyfile_pn = nil, private_keyfile_pn = nil)
      # log_level = :debug
      log_level = :info
      Secretmgr.log_init(log_level)

      home_pn = Pathname.new(Dir.home)
      valid_public_keyfile_pn = valid_public_keyfile(public_keyfile_pn)
      valid_private_keyfile_pn = valid_private_keyfile(private_keyfile_pn)
      return unless valid_public_keyfile_pn && valid_private_keyfile_pn

      @secret = Secret.new(home_pn, secret_dir_pn, public_keyfile_pn, private_keyfile_pn)
    end

    def valid?
      !@secret.nil?
    end

    def set_setting_for_plain(plain_setting_file_pn, plain_secret_file_pn)
      @plain_setting_file_pn = plain_setting_file_pn
      @plain_secret_file_pn = plain_secret_file_pn
      @plain_dir_pn = @plain_setting_file_pn.parent
      @encrypted_setting_file_pn = @secret.encrypted_setting_file_pn
    end

    def set_setting_for_encrypted(encrypted_setting_file_pn, encrypted_secret_file_pn)
      @encrypted_setting_file_pn = encrypted_setting_file_pn
      @encrypted_secret_file_pn = encrypted_secret_file_pn
    end

    def setup
      setup_setting
      setup_secret
      setup_secret_for_json_file
    end

    def setup_setting
      content = File.read(@plain_setting_file_pn)

      @setting = YAML.safe_load(content)
      Loggerxs.debug @setting
      # pp "@setting=#{@setting}"
      # puts "setup_setting    @setting=#{@setting}"
      encrypted_text = @secret.encrypt_with_public_key(content)
      dest_setting_file_pn = @secret.make_pair_file_pn(@plain_setting_file_pn, YML)

      Loggerxs.debug "setup_setting dest_setting_file_pn=#{dest_setting_file_pn}"
      Loggerxs.debug "setup_setting dest_setting_file_pn=#{dest_setting_file_pn}"
      File.write(dest_setting_file_pn, encrypted_text)
    end

    def setup_secret
      plaintext = File.read(@plain_secret_file_pn)
      # puts "setup_secret @setting=#{@setting}"
      encrypted_text = @secret.encrypt_with_common_key(plaintext,
                                                       @setting[SETTING_KEY],
                                                       @setting[SETTING_IV])
      dest_secret_file_pn = @secret.make_pair_file_pn(@plain_secret_file_pn, YML)
      Loggerxs.debug "setup_secret dest_secret_file_pn=#{dest_secret_file_pn}"
      File.write(dest_secret_file_pn, encrypted_text)
    end

    def remove_last_extension(pathn)
      parent = pathn.parent
      basename = pathn.basename
      ext = basename.extname
      base = basename.basename(ext)
      parent + base           
    end

    def setup_secret_for_json_file
      top_pn = @plain_dir_pn + JSON_FILE_DIR
      top_pn.find do |x|
        next if x.directory?

        relative_path = x.relative_path_from(@plain_dir_pn)
        new_relative_path = remove_last_extension(relative_path)
        Loggerxs.debug("################ relative_path=#{relative_path}")
        Loggerxs.debug("################ new_relative_path=#{new_relative_path}")
        @secret.encrypt_and_copy(x, new_relative_path, @setting[SETTING_KEY], @setting[SETTING_IV])
      end
    end

    def set_setting_for_query(*dirs)
      @valid_dirs = dirs.flatten.compact
      @target, @sub_target, _tmp = @valid_dirs
      # p "@valid_dirs=#{@valid_dirs}"
      @file_format = @secret.file_format(@target, @sub_target)
      Loggerxs.debug "@secret_dir_pn=#{@secret_dir_pn}"
      Loggerxs.debug "dirs=#{dirs}"
      Loggerxs.debug "@encrypted_secret_file_pn=#{@encrypted_secret_file_pn}"

      @encrypted_secret_file_pn = @secret.get_file_path(dirs)
    end

    def load_setting
      Loggerxs.debug "load_setting @encrypted_setting_file_pn=#{@encrypted_setting_file_pn}"
      encrypted_text = File.read(@encrypted_setting_file_pn)
      Loggerxs.debug "load_setting encrypted_text=#{encrypted_text}"
      decrypted_text = @secret.decrypt_with_private_key(encrypted_text)
      setting = YAML.safe_load(decrypted_text)
      @key = setting[SETTING_KEY]
      Loggerxs.debug "load_setting @key=#{@key}"
      @iv = setting[SETTING_IV]
      Loggerxs.debug "load_setting @iv=#{@iv}"
    end

    def load_and_decrypt
      Loggerxs.debug("@encrypted_secret_file_pn=#{@encrypted_secret_file_pn}")
      base64_text = File.read(@encrypted_secret_file_pn)
      encrypted_content = Base64.decode64(base64_text)
      begin
        @decrpyted_content = @secret.decrypt_with_common_key(encrypted_content, @key, @iv)
        @content = case @file_format
                   when FORMAT_JSON
                     @decrpyted_content
                   when FORMAT_YAML
                     @secret_content = YAML.safe_load(@decrpyted_content)
                     @sub_target ? @secret_content[@target][@sub_target] : @secret_content[@target]
                   else
                     ""
                   end
      rescue StandardError => e
        Loggerxs.error e
        Loggerxs.error e.message
        Loggerxs.error e.backtrace
        Loggerxs.error "Can't dencrypt #{@encrypted_setting_file_pn}"
      end
      @content
    end

    def load
      load_setting
      load_and_decrypt
    end

    def make(_target, _sub_target)
      case @file_format
      when FORMAT_JSON
        @content
      when FORMAT_YAML
        @content.map do |item|
          %(export #{item[0]}=#{item[1]})
        end.flatten
      else
        ""
      end
    end

    def valid_private_keyfile(path, default_path = ".ssh/id_rsa")
      valid_pathname(path, default_path)
    end

    def valid_public_keyfile(path, default_path = ".ssh/id_rsa.pub")
      valid_pathname(path, default_path)
    end

    def valid_pathname(path, default_path)
      pathn = path
      pathn = Pathname.new(Dir.home) + default_path if Util.nil_or_dontexist?(path)
      pathn = nil if Util.nil_or_dontexist?(pathn)
      pathn
    end
  end
end
