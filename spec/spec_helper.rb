# frozen_string_literal: true

require "secretmgr"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

def encrypt_decrypt(plaintext, key, ivalue)
  encx = OpenSSL::Cipher.new(CIPHER_NAME)
  encx.encrypt
  encx.key = key
  encx.iv = ivalue
  # str に与えた文字列を暗号化します。
  encrypted_text = encx.update(plaintext) + encx.final
  base64_text = Base64.encode64(encrypted_text)
  File.write("a.txt", base64_text)
  base64_text2 = File.read("a.txt")
  plaintext = Base64.decode64(base64_text2)

  decx = OpenSSL::Cipher.new(CIPHER_NAME)
  decx.decrypt
  decx.key = key
  decx.iv = ivalue
  data = decx.update(plaintext)
  final_data = decx.final
  decrypted_data = data + final_data
  decrypted_data.force_encoding("UTF-8")

  decrypt(plaintext, key, ivalue)
end
