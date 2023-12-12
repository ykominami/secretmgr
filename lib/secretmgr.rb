# frozen_string_literal: true

require "openssl"
require "base64"
require "multi_json"

require_relative "secretmgr/version"
require_relative "secretmgr/secretmgr"
require_relative "secretmgr/config"

module Secretmgr
  INSTALLED_APP = "installed"
  WEB_APP = "web"
  CLIENT_ID = "client_id"
  CLIENT_SECRET = "client_secret"
  CIPHER_NAME = "AES-256-CBC"

  class Error < StandardError; end
  # Your code goes here...
end
