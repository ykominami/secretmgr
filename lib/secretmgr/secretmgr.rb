# frozen_string_literal: true
require 'pp'

module Secretmgr
  # 秘匿情報マネージャ
  class Secretmgr
    def initialize(setting_file, secret_file)
      @setting_file = setting_file
      @secret_file = secret_file

      # pemフォーマットの公開鍵ファイルの内容を取得
      path = File.join(ENV['HOME'], '.ssh', 'pem')
      pub_key = File.read(path)
      # 鍵をOpenSSLのオブジェクトにする
      @public_key = OpenSSL::PKey::RSA.new(pub_key)
      path = File.join(ENV['HOME'], '.ssh', 'id_rsa_no')
      private_key = File.read(path)
      @private_key = OpenSSL::PKey::RSA.new(private_key)

      @mode = OpenSSL::PKey::RSA::PKCS1_PADDING
    end

    def load_setting
      encrypted_text = File.read(@setting_file)
      # puts "encrypted_text=#{encrypted_text}"
      decrypted_text = decrypt_with_private_key(encrypted_text)
      @setting = YAML.load(decrypted_text)
      @key = @setting["key"]
      @iv = @setting["iv"]
    end

    def load_secret
      base64_text = File.read(@secret_file)
      encrypted_content = Base64.decode64(base64_text)

      decrpyted_content = decrypt_with_common_key(encrypted_content, @key, @iv)
      # puts "decrpyted_content=#{decrpyted_content}"
      @secret = YAML.load(decrpyted_content)
      # pp @secret
    end

    def load
      load_setting
      load_secret
    end

    def setup_setting
      hash = {}
      content = File.read(@setting_file)
      @setting = Ykxutils::yaml_load_compati(content)
      # content = YAML.dump(@setting)
      encrypted_text = encrypt_with_public_key(content)
      dest_ssetting_file = make_pair_file_path(@setting_file, "yml")

      File.open(dest_ssetting_file, "w"){ |file|
        file.write(encrypted_text)
      }
    end

    def setup_secret
      plaintext = File.read(@secret_file)
      encrypted_text = encrypt_with_common_key(plaintext, @setting["key"], @setting["iv"])
      dest_secret_yaml = make_pair_file_path(@secret_file, "yml")

      File.open(dest_secret_yaml, "w"){ |file|
        file.write(encrypted_text)
      }
    end

    def setup
      setup_setting
      setup_secret
    end

    def make_pair_file_path(file_path, ext)
      basename = File.basename(file_path)
      extname = File.extname(basename)
      return nil if extname == ext
      basename = File.basename(file_path, ".*")
      dirname = File.dirname(file_path)
      File.join(dirname, %!#{basename}.#{ext}!)
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
      decrypted_data = @private_key.private_decrypt(
        Base64.decode64(base64_text),
        OpenSSL::PKey::RSA::PKCS1_OAEP_PADDING)
    end

    # 引数 str を暗号化した結果を返す
    def encrypt_with_common_key(plaintext, key, iv)
      encx = OpenSSL::Cipher.new(CIPHER_NAME)
      encx.encrypt
      encx.key = key
      encx.iv = iv
      # str に与えた文字列を暗号化します。
      encrypted_text = encx.update(plaintext) + encx.final

      Base64.encode64(encrypted_text)
    end

    def decrypt_with_common_key(encrypted_data, key, iv)
      decx = OpenSSL::Cipher.new(CIPHER_NAME)
      decx.decrypt
      decx.key = key
      decx.iv = iv
      data = decx.update(encrypted_data)
      final_data = decx.final
      decrypted_data = data + final_data
      decrypted_data.force_encoding("UTF-8")
    end

    def make(template_dir, target, sub_target)
      puts("template_dir=#{template_dir}")
      puts("target=#{target}")
      puts("sub_target=#{sub_target}")
      # puts("@secret=#{@secret}")
      # pp @secret[target][sub_target]
      pp @secret[target]
      pp @secret[target][sub_target]
    end
  end
end
