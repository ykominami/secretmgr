# frozen_string_literal: true

RSpec.describe Secretmgr do
  before do
  	@secret_file = "config.json"
  	@spec_dir_pn = Pathname.new(__FILE__).parent
  	@secret_file_pn = Pathname.new(@secret_file)

  	@test_data_dir_pn = @spec_dir_pn + 'test_data'
    @secret_dir_pn = @test_data_dir_pn + 'secret'
    @plain_dir_pn = @test_data_dir_pn + 'plain'
    @plain_setting_file_pn = @plain_dir_pn + 'setting.txt'
    @plain_secret_file_pn = @plain_dir_pn + 'secret.txt'
  end

  it "has a version number" do
    expect(Secretmgr::VERSION).not_to be nil
  end

  it "encrypt plaintext" do
	# secret_dir_pn = Pathname.new(@secret_dir)
	#plain_setting_file_pn = Pathname.new(@plain_setting_file)
	#plain_secret_file_pn = Pathname.new(@plain_secret_file)
	puts("@plain_setting_file_pn=#{@plain_setting_file_pn}")
	puts("@plain_secret_file_pn=#{@plain_secret_file_pn}")
  	sm = Secretmgr::Secretmgr.new(@secret_dir_pn, @plain_setting_file_pn, @plain_secret_file_pn)
  	#sm = Secretmgr::Secretmgr.new(@secret_dir_pn)
    sm.setup

  end

  it "decrypt encrypted text" do
  	target = "TEST"
  	sub_target = "subtest"
	
  	sm = Secretmgr::Secretmgr.create(secret_dir_pn, plain_setting_file_pn, plain_secret_file_pn)

    sm.set_setting_for_query(target, sub_target)

    content = sm.load
    File.write(secret_file_pn, content)

    expect(spec_file_on.exist?).to eq(true)
  end
end
