# frozen_string_literal: true

RSpec.describe Secretmgr do
  Secretmgr::Secretmgr.reset_init_count
  log_level = :info
  # log_level = :debug
  Secretmgr::Secretmgr.log_init(log_level)

  let(:tdata) do
    test_data_setup
  end
  let(:home_dir_pn) { make_home_dir_pn }
  let(:test_data_dir_pn) { make_test_data_dir_pn }

  def create_globalsetting(global_setting_file_pn)
    global_setting = Secretmgr::Globalsetting.new(global_setting_file_pn)
    global_setting.ensure
    global_setting.load
    global_setting
  end

  it "has a version number" do
    expect(Secretmgr::VERSION).not_to be_nil
  end

  it "encrypt plain text" do
    #      public_key_filename: "id_rsa_no_y.pub.pem.1",
    #      private_key_filename: "id_rsa_no_y")

    tdata = test_data_setup(test_data_dir_pn)
    tdata.encrypted_setting_file_pn.delete if tdata.encrypted_setting_file_pn.exist?
    tdata.encrypted_secret_file_pn.delete if tdata.encrypted_secret_file_pn.exist?
    global_setting_file_pn = Pathname.new(tdata.global_setting_file)
    global_setting = create_globalsetting(global_setting_file_pn)
    inst = Secretmgr::Secretmgr.new(global_setting, tdata.secret_dir_pn, tdata.secret_key_dir_pn, "setup",
                                    public_keyfile_pn: tdata.public_keyfile_pn)
    inst.set_setting_for_plain(tdata.plain_setting_file, tdata.plain_secret_file)
    inst.setup
    expect(Pathname.new(tdata.encrypted_setting_file)).to exist
    expect(Pathname.new(tdata.encrypted_secret_file)).to exist
  end

  it "decrypt encrypted text" do
    tdata = test_data_setup(test_data_dir_pn)
    target = "TEST"
    subtarget = "subtest"
    global_setting_file_pn = Pathname.new(tdata.global_setting_file)
    global_setting = create_globalsetting(global_setting_file_pn)
    inst = Secretmgr::Secretmgr.new(global_setting, tdata.secret_dir_pn, tdata.secret_key_dir_pn, "data")
    inst.set_setting_for_encrypted(tdata.encrypted_setting_file, tdata.encrypted_secret_file)
    inst.set_setting_for_query(target, subtarget)
    inst.load
    ret = inst.convert
    expect(ret.size).not_to eq(0)
  end
end
