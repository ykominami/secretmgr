module Secretmgr
  class Secret
    require "rspec/expectations"

    include RSpec::Matchers

    FORMAT_FILE = "format.txt".freeze
    SSH_DIR = ".ssh".freeze
    RSA_PRIVATE_FILE = "id_rsa_no".freeze
    RSA_PUBLIC_PEM_FILE = "id_rsa_no.pub.pem".freeze
    SETTING_FILE = "setting.yml".freeze
    SECRET_FILE = "secret.yml".freeze

    def initialize(home_pn, secret_dir_pn, public_keyfile_pn, private_keyfile_pn)
      @content = nil
      @home_pn = home_pn
      @secret_dir_pn = secret_dir_pn

      @format_config = Config.new(@secret_dir_pn, FORMAT_FILE)
      Loggerxs.debug "Secret public_keyfile_pn=#{public_keyfile_pn}"
      Loggerxs.debug "Secret private_keyfile_pn=#{private_keyfile_pn}"

      @public_key = create_public_key(public_keyfile_pn)
      @private_key = create_private_key(private_keyfile_pn)
      @mode = OpenSSL::PKey::RSA::PKCS1_PADDING
    end

    def create_public_key(public_keyfile_pn)
      key_obj = nil
      pub_key = nil
      pub_key = File.read(public_keyfile_pn) if public_keyfile_pn.exist?
      Loggerxs.debug "0 public_keyfile_pn=#{public_keyfile_pn}"
      if pub_key.nil? || pub_key.empty?
        pub_pn = @home_pn + SSH_DIR + RSA_PUBLIC_PEM_FILE
        pub_key = File.read(pub_pn)
        Loggerxs.debug "2 pub_key="
      end
      unless pub_key.nil?
        # 鍵をOpenSSLのオブジェクトにする
        key_obj = OpenSSL::PKey::RSA.new(pub_key)
        Loggerxs.debug "3 key_obj="
      end
      key_obj
    end

    def create_private_key(private_keyfile_pn)
      key_obj = nil
      private_key = nil
      Loggerxs.debug "20 private_keyfile_pn=#{private_keyfile_pn}"
      private_key = File.read(private_keyfile_pn) if private_keyfile_pn.exist?
      Loggerxs.debug "21 private_key="
      if private_key.nil? || private_key.empty?
        private_pn = @home_pn + SSH_DIR + RSA_PRIVATE_FILE
        private_key = File.read(private_pn)
        Loggerxs.debug "22 private_key="
      end
      unless private_key.nil?
        private_key = File.read(private_keyfile_pn)
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

    def make_pair_file_pn(file_pn, ext)
      basename = file_pn.basename
      extname = basename.extname
      return nil if extname == ext

      basename = file_pn.basename(".*")
      @secret_dir_pn + %(#{basename}.#{ext})
    end

    def encrypted_setting_file_pn
      @secret_dir_pn + SETTING_FILE
    end

    def encrypted_secret_file_pn
      @secret_dir_pn + SECRET_FILE
    end

    def encrypt_with_public_key(data)
      Base64.encode64(
        @public_key.public_encrypt(
          data,
          OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
        )
      ).delete("\n")
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
      @private_key.private_decrypt(
        Base64.decode64(base64_text),
        OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING
      )
    end

    # 引数 str を暗号化した結果を返す
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
  end
end
