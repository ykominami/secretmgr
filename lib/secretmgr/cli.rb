require "pathname"
require "yaml"
require "optparse"

module Secretmgr
  class Cli
    EXIT_CODE_SUCCESS = 0
    EXIT_CODE_FAILURE = 10

    CLI_OPTION_SUCCESS = 100
    CLI_OPTION_ERROR_NIL = 110
    CLI_OPTION_ERROR_DOES_NOT_EXIST = 120
    CLI_OPTION_ERROR_ZERO = 130

    FILE_OPTION = 10
    DIRECTORY_OPTION = 20

    def initialize
      # log_level = :debug
      log_level = :info
      Secretmgr.log_init(log_level)
      # log_level = :info
      Loggerxs.init("log_", "log.txt", ".", true, log_level)
      @params = {}

      @opt = OptionParser.new
      @opt.banner = "usage: secretmgr2 [@option]"
      @opt.on("-c", "--cmd command") { |v| @params[:cmd] = v }
      @opt.on("-s", "--secret_dir sdir") { |v| @params[:secret_dir] = v }
      @opt.on("-u", "--public_keyfile file") { |v| @params[:public_keyfile] = v }
      @opt.on("-r", "--private_keyfile file") { |v| @params[:private_keyfile] = v }

      @opt.on("-F", "--encrypted_setting_file file") { |v| @params[:encrypted_setting_file] = v }
      @opt.on("-e", "--encrypted_secret_file file") { |v| @params[:encrypted_secret_file] = v }

      @opt.on("-f", "--plain_setting_file file") { |v| @params[:plain_setting_file] = v }
      @opt.on("-p", "--plain_secret_file file") { |v| @params[:plain_secret_file] = v }
      #      @opt.on("-u", "--public_keyfile file") { |v| @params[:public_keyfile] = v }

      @opt.on("-t", "--target word") { |v| @params[:target] = v }
      @opt.on("-b", "--subtarget word") { |v| @params[:subtarget] = v }
    end

    def arg_parse(argv)
      ret = true
      @opt.parse!(argv)
      Loggerxs.debug @params
      @cmd = @params[:cmd]

      @secret_dir_pn = Pathname.new(@params[:secret_dir]) if @params[:secret_dir]
      @encrypted_setting_file_pn = Pathname.new(@params[:encrypted_setting_file]) if @params[:encrypted_setting_file]
      @encrypted_secret_file_pn = Pathname.new(@params[:encrypted_secret_file]) if @params[:encrypted_secret_file]
      @public_keyfile_pn = Pathname.new(@params[:public_keyfile]) if @params[:public_keyfile]
      @private_keyfile_pn = Pathname.new(@params[:private_keyfile]) if @params[:private_keyfile]

      @plain_setting_file_pn = Pathname.new(@params[:plain_setting_file]) if @params[:plain_setting_file]
      @plain_secret_file_pn = Pathname.new(@params[:plain_secret_file]) if @params[:plain_secret_file]

      @target = @params[:target]
      @subtarget = @params[:subtarget]

      fail_count = 0
      fail_count += directory_option_error?(@secret_dir_pn, "-s")
      fail_count += file_option_error?(@public_keyfile_pn, "-u")
      Loggerxs.debug "@private_keyfile_pn=#{@private_keyfile_pn}"
      fail_count += file_option_error?(@private_keyfile_pn, "-r")

      if @cmd == "setup"
        fail_count += file_option_error?(@plain_setting_file_pn, "-f")
        fail_count += file_option_error?(@plain_secret_file_pn, "-p")
        fail_count += file_specified_option_error?(@encrypted_setting_file_pn, "-F")
        fail_count += file_specified_option_error?(@encrypted_secret_file_pn, "-e")
      else
        # debugger
        @target = @params[:target]
        @subtarget = @params[:subtarget]
        fail_count += string_option_error?(@target, "-t")
        fail_count += string_option_error?(@subtarget, "-b")
        fail_count += file_option_error?(@encrypted_setting_file_pn, "-F")
        fail_count += file_option_error?(@encrypted_secret_file_pn, "-e")
      end

      ret = false if fail_count.positive?
      Loggerxs.debug "fail_count=#{fail_count}"
      Loggerxs.debug "ret=#{ret}"
      ret
    end

    def directory_option_error?(pathn, option_name)
      path_option_error?(pathn, option_name, DIRECTORY_OPTION)
    end

    def file_option_error?(pathn, option_name)
      path_option_error?(pathn, option_name, FILE_OPTION)
    end

    def file_specified_option_error?(pathn, option_name)
      path_specified_option_error?(pathn, option_name, FILE_OPTION)
    end

    def path_specified_option_error?(pathn, _option_name, _kind = FILE_OPTION)
      fail_count = 0
      fail_count = 1 if pathn.nil?
      fail_count
    end

    def path_option_error?(pathn, option_name, kind = FILE_OPTION)
      fail_count = 0
      if Util.nil_or_dontexist?(pathn)
        if kind == FILE_OPTION
          Loggerxs.error "Can't find file(#{pathn}) which specified by #{option_name}"
        else
          Loggerxs.error "Can't find directory(#{pathn}) which specified by #{option_name}"
        end
        fail_count = 1
      elsif kind == FILE_OPTION
        fail_count = 1 unless pathn.file?
      elsif !pathn.directory?
        fail_count = 1
      end
      fail_count
    end

    def string_option_error?(str, option_name)
      fail_count = 0
      if Util.nil_or_zero?(str)
        Loggerxs.error "nil or size zero(#{str}) which specified by #{option_name}"
        fail_count = 1
      end
      fail_count
    end

    def execute
      ret = nil
      inst = Secretmgr.new(@secret_dir_pn, @public_keyfile_pn, @private_keyfile_pn)
      return EXIT_CODE_FAILURE unless inst.valid?

      inst.set_setting_for_encrypted(@encrypted_setting_file_pn, @encrypted_secret_file_pn)

      case @cmd
      when "setup"
        Loggerxs.debug "setup 1"
        inst.set_setting_for_plain(@plain_setting_file_pn, @plain_secret_file_pn)
        Loggerxs.debug "setup 2"
        ret = inst.setup
        Loggerxs.debug "setup ret=#{ret}"
      else
        inst.set_setting_for_query(@target, @subtarget)
        inst.load
        ret = inst.make(@target, @subtarget)
      end
      ret
    end
  end
end
