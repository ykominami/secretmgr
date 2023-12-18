RSpec.describe Secretmgr::Cli do
  let(:test_data) do
    Struct.new(:ssh_dir, :secret_dir, :plain_dir, :public_keyfile, :private_keyfile, :encrypted_setting_file,
               :encrypted_secret_file, :plain_secret_file, :plain_setting_file)
  end
  let(:home_dir_pn) { Pathname.new(Dir.home) }
  let(:test_data_dir_pn) { Pathname.new(__FILE__).parent.parent + "test_data" }

  def test_data_setup(home_dir_pn,
                      secret_dir: nil,
                      plain_dir: nil,
                      public_key_filename: nil,
                      private_key_filename: nil,
                      public_key_file_pn: nil,
                      private_key_file_pn: nil,
                      encrypted_secret_file_pn: nil,
                      encrypted_setting_file_pn: nil)
    # Create an instance of the Struct class
    ssh_dir_pn = home_dir_pn + ".ssh"
    secret_dir_pn = home_dir_pn + (secret_dir || "secret")
    plain_dir_pn = home_dir_pn + (plain_dir || "plain")
    encrypted_setting_file_pn ||= secret_dir_pn + "setting.yml"

    encrypted_secret_file_pn ||= secret_dir_pn + "secret.yml"

    unless public_key_file_pn
      public_key_filename ||= "id_rsa_no.pub.pem"
      ssh_dir_pn + public_key_filename
    end

    unless private_key_file_pn
      public_key_filename = "id_rsa_no.pub.pem" unless private_key_filename
      ssh_dir_pn + private_key_filename
    end

    test_data.new(
      ssh_dir_pn,
      secret_dir_pn,
      plain_dir_pn,
      ssh_dir_pn + public_key_filename,
      ssh_dir_pn + private_key_filename,
      encrypted_setting_file_pn,
      encrypted_secret_file_pn,
      plain_dir_pn + "secret.txt",
      plain_dir_pn + "setting.txt"
    )
  end

  describe "#execute" do
    context "when cmd is 'setup'" do
      it "calls set_setting_for_plain, setup methods" do
        Secretmgr::Secretmgr.reset_init_count
        tdata = test_data_setup(test_data_dir_pn, public_key_filename: "id_rsa_no_y.pub.pem.1",
                                                  private_key_filename: "id_rsa_no_y")
        args = %W[-c setup
                  -s #{tdata.secret_dir}
                  -f #{tdata.plain_setting_file}
                  -p #{tdata.plain_secret_file}
                  -u #{tdata.public_keyfile}
                  -r #{tdata.private_keyfile}
                  -F #{tdata.encrypted_setting_file}
                  -e #{tdata.encrypted_secret_file}]

        inst = described_class.new
        inst.arg_parse(args)
        inst.execute
        expect(tdata.encrypted_setting_file).to exist
        expect(tdata.encrypted_secret_file).to exist
      end
    end

    context "when cmd is not 'setup'" do
      it "calls set_setting_for_encrypted, set_setting_for_query, load, and make methods" do
        Secretmgr::Secretmgr.reset_init_count
        tdata = test_data_setup(test_data_dir_pn, public_key_filename: "id_rsa_no_y.pub.pem.1",
                                                  private_key_filename: "id_rsa_no_y")

        target = "TEST"
        subtarget = "subtest"

        args = %W[-c data
                  -s #{tdata.secret_dir}
                  -u #{tdata.public_keyfile}
                  -r #{tdata.private_keyfile}
                  -F #{tdata.encrypted_setting_file}
                  -e #{tdata.encrypted_secret_file}
                  -t #{target}
                  -b #{subtarget}]
        inst = described_class.new
        inst.arg_parse(args)
        ret = inst.execute
        expect(ret.size).not_to eq(0)
      end
    end
  end
end
