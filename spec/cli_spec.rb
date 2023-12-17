RSpec.describe Secretmgr::Cli do
  describe "#execute" do
    context "when cmd is 'setup'" do
      it "calls set_setting_for_plain, setup methods" do
        secret_dir_pn = Pathname.new(__FILE__).parent + "test_data/secret"
        plain_setting_file_pn = Pathname.new(__FILE__).parent + "test_data/plain/setting.txt"
        plain_secret_file_pn = Pathname.new(__FILE__).parent + "test_data/plain/secret.txt"
        encrypted_setting_file_pn = Pathname.new(__FILE__).parent + "test_data/secret/setting.yml"
        encrypted_secret_file_pn = Pathname.new(__FILE__).parent + "test_data/secret/secret.yml"

        public_keyfile_pn = Pathname.new(__FILE__).parent + "test_data/.ssh/id_rsa_no_y.pub.pem.1"
        private_keyfile_pn = Pathname.new(__FILE__).parent + "test_data/.ssh/id_rsa_no_y"
        args = %W[-c setup
                  -s #{secret_dir_pn}
                  -f #{plain_setting_file_pn}
                  -p #{plain_secret_file_pn}
                  -u #{public_keyfile_pn}
                  -r #{private_keyfile_pn}
                  -F #{encrypted_setting_file_pn}
                  -e #{encrypted_secret_file_pn}]
        encrypted_setting_file_pn.delete if encrypted_setting_file_pn.exist?
        encrypted_secret_file_pn.delete if encrypted_secret_file_pn.exist?

        inst = Secretmgr::Cli.new
        inst.arg_parse(args)
        inst.execute
        expect(encrypted_setting_file_pn.exist?).to be_truthy
        expect(encrypted_secret_file_pn.exist?).to be_truthy
      end
    end

    context "when cmd is not 'setup'" do
      it "calls set_setting_for_encrypted, set_setting_for_query, load, and make methods" do
        secret_dir_pn = Pathname.new(__FILE__).parent + "test_data/secret"
        encrypted_setting_file_pn = Pathname.new(__FILE__).parent + "test_data/secret/setting.yml"
        encrypted_secret_file_pn = Pathname.new(__FILE__).parent + "test_data/secret/secret.yml"
        public_keyfile_pn = Pathname.new(__FILE__).parent + "test_data/.ssh/id_rsa_no_y.pub.pem.1"
        private_keyfile_pn = Pathname.new(__FILE__).parent + "test_data/.ssh/id_rsa_no_y"
        plain_setting_file_pn = Pathname.new(__FILE__).parent + "test_data/plain/setting.txt"
        plain_secret_file_pn = Pathname.new(__FILE__).parent + "test_data/plain/secret.txt"
        target = "TEST"
        subtarget = "subtest"

        args = %W[-c data
                  -s #{secret_dir_pn}
                  -u #{public_keyfile_pn}
                  -r #{private_keyfile_pn}
                  -F #{encrypted_setting_file_pn}
                  -e #{encrypted_secret_file_pn}
                  -t #{target}
                  -b #{subtarget}]
        inst = Secretmgr::Cli.new
        inst.arg_parse(args)
        ret = inst.execute
        expect(ret.size).not_to eq(0)
      end
    end
  end
end
