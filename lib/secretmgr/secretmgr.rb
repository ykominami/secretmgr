# frozen_string_literal: true

require "pathname"

module Secretmgr
  # 秘匿情報マネージャ
  class Secretmgr
    attr_reader :decrypted_text, :secret

    class << self
      def create(secret_dir_pn, plain_setting_file_pn, plain_secret_file_pn)
        @inst = Secretmgr.new(secret_dir_pn)
        @inst.set_setting_for_data(plain_setting_file_pn, plain_secret_file_pn)
        @inst
      end
    end

    def initialize(secret_dir_pn)
      @content = nil
      @secret_dir_pn = secret_dir_pn
      @encrypted_setting_file_pn = "#{@secret_dir_pn}setting.yml"

      @format_config = Config.new(@secret_dir_pn, "format.txt")
      home_dir = ENV["HOME"]
      @home_pn = Pathname.new(home_dir)
      # pemフォーマットの公開鍵ファイルの内容を取得
      path = File.join(home_dir, ".ssh", "pem")
      pub_key = File.read(path)
      # 鍵をOpenSSLのオブジェクトにする
      @public_key = OpenSSL::PKey::RSA.new(pub_key)
      path = File.join(home_dir, ".ssh", "id_rsa_no")
      private_key = File.read(path)
      @private_key = OpenSSL::PKey::RSA.new(private_key)

      @mode = OpenSSL::PKey::RSA::PKCS1_PADDING
    end

    def set_setting_for_data(plain_setting_file_pn, plain_secret_file_pn)
      @plain_setting_file_pn = plain_setting_file_pn
      @plain_secret_file_pn = plain_secret_file_pn
      @plain_dir_pn = @plain_setting_file_pn.parent
    end

    def setup
      setup_setting
      setup_secret
      setup_secret_for_json_file
    end

    def setup_setting
      content = File.read(@plain_setting_file_pn)
      @setting = Ykxutils.yaml_load_compati(content)
      # content = YAML.dump(@setting)
      encrypted_text = encrypt_with_public_key(content)
      dest_setting_file_pn = make_pair_file_pn(@secret_dir_pn, @plain_setting_file_pn, "yml")

      File.write(dest_setting_file_pn, encrypted_text)
    end

    def make_pair_file_pn(dest_dir_pn, file_pn, ext)
      basename = file_pn.basename
      extname = basename.extname
      return nil if extname == ext

      basename = file_pn.basename(".*")
      dest_dir_pn + %(#{basename}.#{ext})
    end

    def setup_secret
      plaintext = File.read(@plain_secret_file_pn)
      encrypted_text = encrypt_with_common_key(plaintext, @setting["key"], @setting["iv"])
      dest_secret_file_pn = make_pair_file_pn(@secret_dir_pn, @plain_secret_file_pn, "yml")
      dest_secret_file_pn.realpath
      # puts "setup_secret dest_secret_file_pn=#{dest_secret_file_pn}"
      # puts "real_pn=#{real_pn}"
      File.write(dest_secret_file_pn, encrypted_text)
    end

    def setup_secret_for_json_file
      top_pn = "#{@plain_dir_pn}JSON_FILE"
      top_pn.find do |x|
        # p x if x.file?
        relative_path = x.relative_path_from(@plain_dir_pn)
        # p relative_path
        encrypt_and_copy(x, @secret_dir_pn, relative_path)
      end
    end

    def encrypt_and_copy(src_pn, dest_top_dir_pn, relative_path)
      dest_pn = dest_top_dir_pn + relative_path
      return unless src_pn.exist? && src_pn.file?

      puts "e_adn_c #{src_pn} -> #{dest_pn}"
      plaintext = File.read(src_pn)
      encrypted_text = encrypt_with_common_key(plaintext, @setting["key"], @setting["iv"])
      File.write(dest_pn, encrypted_text)
    end

    def set_setting_for_query(*dirs)
      @valid_dirs = dirs.flatten.reject(&:nil?)
      @target, @sub_target, _tmp = @valid_dirs
      # p "@valid_dirs=#{@valid_dirs}"
      @file_format = @format_config.file_format(@target, @sub_target)
      p "@file_format=#{@file_format}"
      p "dirs=#{dirs}"
      @encrypted_secret_file_pn = @format_config.get_file_path(@secret_dir_pn, dirs)
    end

    def load_setting
      encrypted_text = File.read(@encrypted_setting_file_pn)
      # puts "encrypted_text=#{encrypted_text}"
      decrypted_text = decrypt_with_private_key(encrypted_text)
      setting = YAML.safe_load(decrypted_text)
      @key = setting["key"]
      @iv = setting["iv"]
      # p "load_settings @key=#{@key}"
      # p "load_settings @iv=#{@iv}"
    end

    def load_secret
      base64_text = File.read(@encrypted_secret_file_pn)
      encrypted_content = Base64.decode64(base64_text)
      begin
        @decrpyted_content = decrypt_with_common_key(encrypted_content, @key, @iv)
        @content = case @file_format
                   when "JSON_FILE"
                     @decrpyted_content
                   when "YAML"
                     @secret = YAML.safe_load(@decrpyted_content)
                     @sub_target ? @secret[@target][@sub_target] : @secret[@target]
                   else
                     ""
                   end
      rescue StandardError => e
        puts e
        puts e.message
        puts e.backtrace
        puts "Can't dencrypt #{@encrypted_setting_file_pn}"
      end
      @content
    end

    def load
      load_setting
      load_secret
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
    def encrypt_with_common_key(plaintext, key, _ivalue)
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
      when "JSON_FILE"
        @content
      when "YAML"
        @content.map do |item|
          %(export #{item[0]}=#{item[1]})
        end.flatten
      else
        ""
      end
    end
  end
end
