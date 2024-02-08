# frozen_string_literal: true

require "pathname"
require "debug"

module Secretmgr
  # 秘匿情報マネージャ
  class Secretmgr
    attr_reader :decrypted_text, :secret

    @log_level = nil
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
    DEFAULT_PRIVATE_KEYFILE = ".ssh/id_rsa"
    DEFAULT_PUBLIC_KEYFILE = ".ssh/id_rsa.pub"

    class << self
      def log_init(log_level)
        return unless @log_level.nil?

        @log_level = log_level
        Loggerxs.init("log_", "log.txt", ".", true, log_level) if @init_count.zero?
        @init_count += 1
      end

      attr_reader :setting_file, :format_file, :ssh_dir, :pem_dir, :no_pass_dir, :no_pass_rsa_dir, :json_file_dir,
                  :setting_key, :setting_iv, :format_json, :format_yaml, :secret_dir

      def str_yml
        @yml
      end

      def str_dot_yml
        @dot_yml
      end
    end

    def initialize(seting, secret_dir_pn, secret_key_dir_pn, ope,
                   public_keyfile_pn: nil, private_keyfile_pn: nil)
      log_level = :info
      # log_level = :debug
      Secretmgr.log_init(log_level)

      @setting = seting
      home_pn = Pathname.new(Dir.home)
      secret_dir_pn = Pathname.new(secret_dir_pn) unless secret_dir_pn.instance_of?(Pathname)
      secret_key_dir_pn = Pathname.new(secret_key_dir_pn) unless secret_key_dir_pn.instance_of?(Pathname)
      secret_key_dir_pn.mkdir unless secret_key_dir_pn.exist?
      default_public_keyfile_pn = secret_key_dir_pn + "id_rsa.pub"
      default_private_keyfile_pn = secret_key_dir_pn + "id_rsa"
      public_keyfile_pn = Pathname.new(public_keyfile_pn) if public_keyfile_pn
      private_keyfile_pn = Pathname.new(private_keyfile_pn) if private_keyfile_pn

      @secret = Secret.new(@setting, home_pn, secret_dir_pn, ope,
                           default_public_keyfile_pn,
                           default_private_keyfile_pn,
                           public_keyfile_pn: public_keyfile_pn,
                           private_keyfile_pn: private_keyfile_pn)
    end

    def valid?
      @secret.valid
      # Loggerxs.debug "1 ret=#{ret}"
      # p  "2 ret=#{ret}"
    end

    def output_public_key(public_keyfile_pn)
      @secret.output_public_key(public_keyfile_pn)
    end

    def create_public_key(public_keyfile_pn)
      @secret.create_public_key(public_keyfile_pn)
    end

    def output_private_key(private_keyfile_pn)
      @secret.output_private_key(private_keyfile_pn)
    end

    def create_private_key(private_keyfile_pn)
      @secret.create_private_key(private_keyfile_pn)
    end

    def set_setting_for_plain(plain_setting_file_pn, plain_secret_file_pn)
      @plain_setting_file_pn = Pathname.new(@plain_setting_file_pn) if @plain_setting_file_pn
      @plain_setting_file_pn ||= Pathname.new(plain_setting_file_pn)
      @plain_secret_file_pn = Pathname.new(@plain_secret_file_pn) if @plain_secret_file_pn
      @plain_secret_file_pn ||= Pathname.new(plain_secret_file_pn)
      @plain_dir_pn = @plain_setting_file_pn.parent
      @encrypted_setting_file_pn = @secret.encrypted_setting_file_pn
      @encrypted_secret_file_pn = @secret.encrypted_secret_file_pn
    end

    def set_setting_for_encrypted(encrypted_setting_file_pn, encrypted_secret_file_pn)
      @encrypted_setting_file_pn = Pathname.new(encrypted_setting_file_pn)
      @encrypted_secret_file_pn = Pathname.new(encrypted_secret_file_pn)
    end

    def setup
      # p "###### setup_setting"
      setup_setting
      # p "###### setup_secret"
      setup_secret
      # p "###### setup_secret_for_json_file"
      setup_secret_for_json_file
    end

    def setup_setting
      puts "setup_setting @plain_setting_file_pn=#{@plain_setting_file_pn}"
      content = File.read(@plain_setting_file_pn)
      puts "setup_setting content=#{content}"
      # @setting = Ykxutils.yaml_load_compati(content)
      @setting = YAML.safe_load(content)
      puts "setup_setting @setting=#{@setting}"
      # content = YAML.dump(@setting)
      encrypted_text = encrypt_with_public_key(content)
      dest_setting_file_pn = make_pair_file_pn(@secret_dir_pn, @plain_setting_file_pn, Secretmgr.str_yml)

      @setting = YAML.safe_load(content)
      # p "setup_setting @setting=#{@setting}"

      Loggerxs.debug @setting
      # pp "@setting=#{@setting}"
      # puts "setup_setting    @setting=#{@setting}"
      encrypted_text = @secret.encrypt_with_public_key(content)
      # puts "setup_setting encrypted_text.size=#{encrypted_text.size}"
      # puts "setup_setting encrypted_text=#{encrypted_text}"
      #
      @secret.decrypt_with_private_key(encrypted_text)
      # puts "setup_setting decrypted_text=#{decrypted_text}"
      # puts "setup_setting decrypted_text.size=#{decrypted_text.size}"

      dest_setting_file_pn = @secret.make_pair_file_pn(@plain_setting_file_pn, YML)

      Loggerxs.debug "setup_setting dest_setting_file_pn=#{dest_setting_file_pn}"
      File.write(dest_setting_file_pn, encrypted_text)
      # p "dest_setting_file_pn=#{dest_setting_file_pn}"
    end

    def setup_secret
      plaintext = File.read(@plain_secret_file_pn)
      puts "setup_secret @setting=#{@setting}"
      encrypted_text = encrypt_with_common_key(plaintext,
                                               @setting[Secretmgr.setting_key],
                                               @setting[Secretmgr.setting_iv])
      dest_secret_file_pn = make_pair_file_pn(@secret_dir_pn, @plain_secret_file_pn, Secretmgr.str_yml)
      dest_secret_file_pn.realpath
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
                   when @format_json
                     @decrpyted_content
                   when @format_yaml
                     @secret = YAML.safe_load(@decrpyted_content)
                     @sub_target ? @secret[@target][@sub_target] : @secret[@target]
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

    def encrypt_with_public_key(data)
      Base64.encode64(
        @public_key.public_encrypt(
          data,
          OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
        )
      ).delete("\n")
    end

    def decrypt_with_private_key(base64_text)
      @private_key.private_decrypt(
        Base64.decode64(base64_text),
        OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      )
    end

    # 引数 str を暗号化した結果を返す
    def encrypt_with_common_key(plaintext, key, ivvalue)
      encx = OpenSSL::Cipher.new(CIPHER_NAME)
      encx.encrypt
      encx.key = key
      encx.iv = ivvalue
      # str に与えた文字列を暗号化します。
      encrypted_text = encx.update(plaintext) + encx.final

      Base64.encode64(encrypted_text)
    end

    def decrypt_with_common_key(encrypted_data, key, ivalue)
      decx = OpenSSL::Cipher.new(CIPHER_NAME)
      decx.decrypt
      decx.key = key
      decx.iv = ivalue
      data = decx.update(encrypted_data)
      final_data = decx.final
      decrypted_data = data + final_data
      decrypted_data.force_encoding("UTF-8")
    end

    def make(_template_dir, _target, _sub_target)
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

    def valid_private_keyfile(path, default_path = DEFAULT_PRIVATE_KEYFILE)
      valid_pathname(path, default_path)
    end

    def valid_public_keyfile(path, default_path = DEFAULT_PUBLIC_KEYFILE)
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
