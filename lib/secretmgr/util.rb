# frozen_string_literal: true

module Secretmgr
  class Util
    class << self
      def nil_or_dontexist?(pathn)
        pathn.nil? || !pathn.exist?
      end

      def nil_or_zero?(str)
        str.nil? || str.empty?
      end
    end
  end
end
