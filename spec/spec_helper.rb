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

def make_home_dir_pn
  Pathname.new(Dir.home)
end

def make_test_data_dir_pn
  Pathname.new(__FILE__).parent + "test_data"
end

def make_test_data
  Struct.new(:ssh_dir,
             :ssh_dir_pn,
             :secret_dir,
             :secret_dir_pn,
             :secret_key_dir,
             :secret_key_dir_pn,
             :global_setting_file_pn,
             :global_setting_file,
             :plain_dir_pn,
             :plain_dir,
             :public_key_filename,
             :public_keyfile,
             :public_keyfile_pn,
             :private_key_filename,
             :private_keyfile,
             :private_keyfile_pn,
             :encrypted_setting_file,
             :encrypted_setting_file_pn,
             :encrypted_secret_file,
             :encrypted_secret_file_pn,
             :plain_secret_file,
             :plain_secret_file_pn,
             :plain_setting_file,
             :plain_setting_file_pn)
end

def test_data_setup(test_data_dir_pn,
                    secret_dir: nil,
                    secret_key_dir: nil,
                    plain_dir: nil,
                    public_key_file_pn: nil,
                    public_key_filename: nil,
                    private_key_file_pn: nil,
                    private_key_filename: nil,
                    encrypted_secret_file_pn: nil,
                    encrypted_setting_file_pn: nil)
  # Create an instance of the Struct class
  # test_data_dir_pn = make_test_data_dir_pn()
  ssh_dir_pn = Pathname.new(test_data_dir_pn) + "secret_key"
  # p "ssh_dir_pn=#{ssh_dir_pn}"
  secret_dir_pn = test_data_dir_pn + (secret_dir || "secret")
  secret_key_dir_pn = test_data_dir_pn + (secret_key_dir || "secret_key")
  plain_dir_pn = test_data_dir_pn + (plain_dir || "plain")
  encrypted_secret_file_pn ||= secret_dir_pn + "secret.yml"
  encrypted_setting_file_pn ||= secret_dir_pn + "setting.yml"
  global_setting_file_pn ||= test_data_dir_pn + "global_setting.yml"
  unless public_key_file_pn
    public_key_filename ||= "id_rsa_no.pub"
    public_key_file_pn = ssh_dir_pn + public_key_filename
    # p "X public_key_file_pn=#{public_key_file_pn}"
  end

  unless private_key_file_pn
    private_key_filename ||= "id_rsa_no"
    private_key_file_pn = ssh_dir_pn + private_key_filename
    # p "X private_key_file_pn=#{private_key_file_pn}"
  end
  plain_secret_file_pn ||= plain_dir_pn + "secret.txt"
  plain_setting_file_pn ||= plain_dir_pn + "setting.txt"
  test_data = make_test_data
  test_data.new(
    ssh_dir_pn.to_s,
    ssh_dir_pn,
    secret_dir_pn.to_s,
    secret_dir_pn,
    secret_key_dir_pn.to_s,
    secret_key_dir_pn,
    global_setting_file_pn,
    global_setting_file_pn.to_s,
    plain_dir_pn,
    plain_dir_pn.to_s,
    public_key_filename,
    public_key_file_pn.to_s,
    public_key_file_pn,
    private_key_filename,
    private_key_file_pn.to_s,
    private_key_file_pn,
    encrypted_setting_file_pn.to_s,
    encrypted_setting_file_pn,
    encrypted_secret_file_pn.to_s,
    encrypted_secret_file_pn,
    plain_secret_file_pn.to_s,
    plain_secret_file_pn,
    plain_setting_file_pn.to_s,
    plain_setting_file_pn
  )
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
