# frozen_string_literal: true

require 'secretmgr'
require 'pathname'


begin
  require 'rspec/core/rake_task'
rescue LoadError => e
  puts e.message
end

begin
  RSpec::Core::RakeTask.new(:spec)
rescue NameError, LoadError => e
  puts e.message
end

begin
  require 'rubocop/rake_task'
rescue LoadError => e
  puts e.message
end

begin
  RuboCop::RakeTask.new
rescue NameError, LoadError => e
  puts e.message
end

desc 'secretmgr setup'
task default: %i[spec rubocop]

desc 'setup'
task :setup do
	home_dir_pn = Pathname.new(Dir.home)
  spec_dir_pn = home_dir_pn + "spec"
  test_data_dir_pn = spec_dir_pn + "test_data"
  plain_dir_pn = test_data_dir_pn + "plain"
  private_dir_pn = test_data_dir_pn + "private"
  ssh_dir_pn = test_data_dir_pn + ".ssh"
  public_keyfile_pn = ssh_dir_pn + "id_rsa_temporary"
  private_keyfile_pn = ssh_dir_pn + "id_rsa_temporary.pub"
  if ssh_dir_pn.exist?
    puts "Exist ssh_dir_pn=#{ssh_dir_pn}"
  else
    puts "Not Exist ssh_dir_pn=#{ssh_dir_pn}"
  end
end

