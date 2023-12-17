# frozen_string_literal: true

RSpec.describe Secretmgr do
  TestData = Struct.new(:ssh_dir, :secret_dir, :plain_dir, :public_keyfile, :private_keyfile, :encrypted_setting_file,
                        :encrypted_secret_file, :plain_secret_file, :plain_setting_file)
  CLI = Secretmgr::Cli.new

  def test_data_setup(home_dir_pn, public_key_filename = "id_rsa_no.pub.pem", private_key_filename = "id_rsa_no.pub")
    # Create an instance of the Struct class
    ssh_dir_pn = home_dir_pn + ".ssh"
    secret_dir_pn = home_dir_pn + "secret"
    plain_dir_pn = home_dir_pn + "plain"
    TestData.new(
      ssh_dir_pn,
      home_dir_pn + "secret",
      home_dir_pn + "plain",
      ssh_dir_pn + public_key_filename,
      ssh_dir_pn + private_key_filename,
      secret_dir_pn + "setting.yml",
      secret_dir_pn + "secret.yml",
      plain_dir_pn + "secret.txt",
      plain_dir_pn + "setting.txt"
    )
  end

  spec_dir_pn = Pathname.new(__FILE__).parent
  let(:home_dir_pn) { Pathname.new(Dir.home) }
  let(:test_data_dir_pn) { spec_dir_pn + "test_data" }

  it "has a version number" do
    expect(Secretmgr::VERSION).not_to be_nil
  end

  it "encrypt plain text" do
    tdata = test_data_setup(test_data_dir_pn, "id_rsa_no_y.pub.pem.1", "id_rsa_no_y")
    cli = Secretmgr::Cli.new
    inst = Secretmgr::Secretmgr.new(cli.loggerx, tdata.secret_dir, tdata.public_keyfile, tdata.private_keyfile)
    inst.set_setting_for_plain(tdata.plain_setting_file, tdata.plain_secret_file)
    inst.setup
    expect(tdata.encrypted_setting_file.exist?).to be_truthy
    expect(tdata.encrypted_secret_file.exist?).to be_truthy
  end

  it "decrypt encrypted text" do
    tdata = test_data_setup(test_data_dir_pn, "id_rsa_no_y.pub.pem.1", "id_rsa_no_y")
    target = "TEST"
    subtarget = "subtest"
    cli = Secretmgr::Cli.new
    inst = Secretmgr::Secretmgr.new(cli.loggerx, tdata.secret_dir, tdata.public_keyfile, tdata.private_keyfile)
    inst.set_setting_for_encrypted(tdata.encrypted_setting_file, tdata.encrypted_secret_file)
    inst.set_setting_for_query(target, subtarget)
    inst.load
    ret = inst.make(target, subtarget)
    expect(ret.size).not_to eq(0)
  end

  it "encrypt plain text with home directory" do
    tdata = test_data_setup(home_dir_pn, "id_rsa_no.pub.pem.1", "id_rsa_no")
    cli = Secretmgr::Cli.new
    inst = Secretmgr::Secretmgr.new(cli.loggerx, tdata.secret_dir, tdata.public_keyfile, tdata.private_keyfile)
    inst.set_setting_for_plain(tdata.plain_setting_file, tdata.plain_secret_file)
    inst.setup
    expect(Pathname.new(tdata.encrypted_setting_file).exist?).to be_truthy
    expect(Pathname.new(tdata.encrypted_secret_file).exist?).to be_truthy
  end

  # Define a Struct class
  it "decrypt encrypted text with home directory" do
    tdata = test_data_setup(home_dir_pn, "id_rsa_no.pub.pem.1", "id_rsa_no")

    target = "TEST"
    subtarget = "subtest"
    cli = Secretmgr::Cli.new
    inst = Secretmgr::Secretmgr.new(cli.loggerx, tdata.secret_dir, tdata.public_keyfile, tdata.private_keyfile)
    inst.set_setting_for_encrypted(tdata.encrypted_setting_file, tdata.encrypted_secret_file)
    inst.set_setting_for_query(target, subtarget)
    inst.load
    ret = inst.make(target, subtarget)
    expect(ret.size).not_to eq(0)
  end
end
