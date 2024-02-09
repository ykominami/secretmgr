# frozen_string_literal: true

RSpec.describe Secretmgr do
  let(:secret_file) { "config.json" }
  let(:spec_dir_pn) { Pathname.new(__FILE__).parent }
  let(:secret_file_pn) { Pathname.new(@secret_file) }
  let(:test_data_dir_pn) { spec_dir_pn + "test_data" }
  let(:secret_dir_pn) { test_data_dir_pn + "secret" }
  let(:plain_dir_pn) { test_data_dir_pn + "plain" }
  let(:plain_setting_file_pn) { plain_dir_pn + "setting.txt" }
  let(:plain_secret_file_pn) { plain_dir_pn + "secret.txt" }

  it "has a version number" do
    expect(Secretmgr::VERSION).not_to be_nil
  end

  it "encrypt plaintext" do
    # secret_dir_pn = Pathname.new(@secret_dir)
    # plain_setting_file_pn = Pathname.new(@plain_setting_file)
    # plain_secret_file_pn = Pathname.new(@plain_secret_file)
    Loggerxs.debug("@plain_setting_file_pn=#{plain_setting_file_pn}")
    Loggerxs.debug("@plain_secret_file_pn=#{plain_secret_file_pn}")
    sm = Secretmgr::Secretmgr.new(secret_dir_pn, plain_setting_file_pn, plain_secret_file_pn)
    # sm = Secretmgr::Secretmgr.new(@secret_dir_pn)
    sm.setup
  end

  it "decrypt encrypted text" do
    target = "TEST"
    sub_target = "subtest"

    sm = Secretmgr::Secretmgr.create(secret_dir_pn, plain_setting_file_pn, plain_secret_file_pn)

    sm.set_setting_for_query(target, sub_target)

    content = sm.load
    File.write(secret_file_pn, content)

    expect(secret_file_pn.exist?).to be(true)
  end
end
