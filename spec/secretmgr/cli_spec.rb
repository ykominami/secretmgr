RSpec.describe Secretmgr::Cli do
  Secretmgr::Secretmgr.reset_init_count
  # log_level = :info
  log_level = :debug
  Secretmgr::Secretmgr.log_init(log_level)

  let(:test_data) do
    make_test_data
  end
  let(:home_dir_pn) { make_home_dir_pn }
  let(:test_data_dir_pn) { make_test_data_dir_pn }

  describe "#execute" do
    context "when cmd is 'setup'" do
      it "calls set_setting_for_plain, setup methods" do
        tdata = test_data_setup(test_data_dir_pn)
        args = %W[-c setup
                  -d #{tdata.secret_dir}
                  -s #{tdata.global_setting_file}
                  -k #{tdata.secret_key_dir}
                  -f #{tdata.plain_setting_file}
                  -p #{tdata.plain_secret_file}
                  -F #{tdata.encrypted_setting_file}
                  -e #{tdata.encrypted_secret_file}]
        tdata.encrypted_setting_file_pn.rmtree
        tdata.encrypted_secret_file_pn.rmtree
        #
        inst = described_class.new
        inst.arg_parse(args)
        inst.execute
        #
        expect(tdata.encrypted_secret_file_pn.exist?).to be(true)
        expect(tdata.encrypted_setting_file_pn.exist?).to be(true)
      end
    end

    context "when cmd is not 'setup'" do
      it "calls set_setting_for_encrypted, set_setting_for_query, load, and make methods" do
        Secretmgr::Secretmgr.reset_init_count
        tdata = test_data_setup(test_data_dir_pn)

        target = "TEST"
        subtarget = "subtest"

        args = %W[-c data
                  -d #{tdata.secret_dir}
                  -k #{tdata.secret_key_dir}
                  -s #{tdata.global_setting_file}
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
