module Secretmgr
  class Secret
    require "rspec/expectations"

    include RSpec::Matchers

    RSA_KEY_SIZE = 2048

    FORMAT_FILE = "format.txt".freeze
    SSH_DIR = ".ssh".freeze
    RSA_PRIVATE_FILE = "id_rsa_no".freeze
    RSA_PUBLIC_PEM_FILE = "id_rsa_no.pub.pem".freeze
    SETTING_FILE = "setting.yml".freeze
    SECRET_FILE = "secret.yml".freeze
    DEFAULT_PUBLIC_KEYFILE = ".ssh/id_rsa.pub".freeze
    DEFAULT_PRIVATE_KEYFILE = ".ssh/id_rsa".freeze
    attr_reader :public_key, :public_keyfile_pn, :private_key, :private_keyfile_pn, :valid

    def initialize(setting, home_pn, secret_dir_pn, ope,
                   default_public_keyfile_pn,
                   default_private_keyfile_pn,
                   public_keyfile_pn: nil,
                   private_keyfile_pn: nil)
      Loggerxs.debug "Secret.initialize secret_dir_pn=#{secret_dir_pn}"
      @mode = OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      @setting = setting
      raise unless secret_dir_pn
      @secret_dir_pn = secret_dir_pn
      @secret_dir_pn = Pathname.new(@secret_dir_pn) unless @secret_dir_pn.instance_of?(Pathname)

      @home_pn = home_pn
      @format_config = Config.new(@secret_dir_pn, FORMAT_FILE)

      @private_key = nil
      @public_key = nil
      @private_key = create_private_key(private_keyfile_pn) if private_keyfile_pn
      @public_key = create_public_key(public_keyfile_pn) if public_keyfile_pn

      @valid = false

      if @private_key.nil? && @public_key.nil?
        case ope
        when "setup"
          # @public_key, @private_key = create_keyfiles()
          @rsa_key, @public_key, @public_key_str, @private_key, @private_key_str = create_keyfiles
          default_public_keyfile_pn ||= @setting.get("default_public_keyfile_pn")
          default_private_keyfile_pn ||= @setting.get("default_private_keyfile_pn")
          output_public_key(default_public_keyfile_pn)
          output_private_key(default_private_keyfile_pn)
          @setting.set("default_public_keyfile_pn", default_public_keyfile_pn)
          @setting.set("default_private_keyfile_pn", default_private_keyfile_pn)
          @setting.save
        else
          default_public_keyfile_pn = @setting.get("default_public_keyfile_pn")
          default_private_keyfile_pn = @setting.get("default_private_keyfile_pn")
          @private_key = create_private_key(default_private_keyfile_pn)
          @public_key = create_public_key(default_public_keyfile_pn)
        end
      end
      @valid = true
    end

    def output_public_key(public_keyfile_pn)
      File.write(public_keyfile_pn, @public_key_str)
      Loggerxs.debug "0 public_keyfile_pn=#{public_keyfile_pn}"
    end

    def create_public_key(public_keyfile_pn)
      key_obj = nil
      pub_key = nil
      pub_key = File.read(public_keyfile_pn) if public_keyfile_pn.exist?
      Loggerxs.debug "0 public_keyfile_pn=#{public_keyfile_pn}"

      unless pub_key.nil?
        # 鍵をOpenSSLのオブジェクトにする
        key_obj = OpenSSL::PKey::RSA.new(pub_key)
        Loggerxs.debug "3 key_obj="
      end
      key_obj
    end

    def output_private_key(private_keyfile_pn)
      File.write(private_keyfile_pn, @private_key_str)
      Loggerxs.debug "0 private_keyfile_pn=#{private_keyfile_pn}"
    end

    def create_private_key(private_keyfile_pn)
      key_obj = nil
      private_key = nil
      Loggerxs.debug "20 private_keyfile_pn=#{private_keyfile_pn}"
      private_key = File.read(private_keyfile_pn) if private_keyfile_pn.exist?
      unless private_key.nil?
        # 鍵をOpenSSLのオブジェクトにする
        key_obj = OpenSSL::PKey::RSA.new(private_key)
        Loggerxs.debug "23 private_key="
      end
      key_obj
    end

    def file_format(target, sub_target)
      @format_config.file_format(target, sub_target)
    end

    def get_file_path(dirs)
      @format_config.get_file_path(@secret_dir_pn, dirs)
    end

    def make_pair_file_pn(dest_dir_pn, file_pn, ext)
      basename = file_pn.basename(".*")
      dest_dir_pn + %(#{basename}.#{ext})
    end

    def encrypted_setting_file_pn
      @secret_dir_pn + SETTING_FILE
    end

    def encrypted_secret_file_pn
      @secret_dir_pn + SECRET_FILE
    end

    def encrypt_with_public_key(data)
      key = nil
      if @public_key.nil?
        return nil if @rsa_key.nil?

        key = @rsa_key
      else
        key = @public_key
      end
      return unless key

      ecrypted_text = key.public_encrypt(
        data,
        @mode
      )
      Base64.encode64(ecrypted_text)
    end

    def encrypt_and_copy(src_pn, relative_path, key, ivx)
      dest_pn = @secret_dir_pn + relative_path
      return unless src_pn.exist? && src_pn.file?

      dest_parent_pn = dest_pn.parent
      dest_parent_pn.mkpath

      plaintext = File.read(src_pn)
      encrypted_text = encrypt_with_common_key(plaintext, key, ivx)
      File.write(dest_pn, encrypted_text)
    end

    def decrypt_with_private_key(base64_text)
      key = nil
      if @private_key.nil?
        return nil if @rsa_key.nil?

        key = @rsa_key
      else
        key = @private_key
      end
      return unless key

      plain_text = Base64.decode64(base64_text)
      key.private_decrypt(
        plain_text,
        @mode
      )
    end

    # 引数 plaintext を暗号化した結果を返す
    def encrypt_with_common_key(plaintext, key, ivalue)
      encx = OpenSSL::Cipher.new(CIPHER_NAME)
      encx.encrypt
      encx.key = key
      encx.iv = ivalue
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

    def create_keyfiles
      rsa_key = OpenSSL::PKey::RSA.new(RSA_KEY_SIZE)
      # 秘密鍵を生成
      private_key = rsa_key
      private_key_str = rsa_key.to_pem

      # 公開鍵を生成
      public_key = rsa_key.public_key
      public_key_str = public_key.to_pem

      Loggerxs.debug "############## create_keyfiles public_key=#{public_key}"
      [rsa_key, public_key, public_key_str, private_key, private_key_str]
    end
  end
end
