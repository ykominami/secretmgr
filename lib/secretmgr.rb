# frozen_string_literal: true

require 'openssl'
require 'base64'
require 'multi_json'
require 'ykxutils'
require 'ykutils'

require_relative "secretmgr/version"
require_relative "secretmgr/secretmgr"

module Secretmgr
  INSTALLED_APP = "installed".freeze
  WEB_APP = "web".freeze
  CLIENT_ID = "client_id".freeze
  CLIENT_SECRET = "client_secret".freeze
  CIPHER_NAME = "AES-256-CBC".freeze

  class Error < StandardError; end
  # Your code goes here...
end
