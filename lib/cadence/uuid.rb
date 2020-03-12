# This is a simple UUIDv5 (SHA1) implementation adopted from:
# https://github.com/rails/rails/blob/master/activesupport/lib/active_support/core_ext/digest/uuid.rb#L18
require 'digest'

module Cadence
  module UUID
    def self.v5(uuid_namespace, name)
      hash = Digest::SHA1.new
      hash.update(uuid_namespace)
      hash.update(name)

      ary = hash.digest.unpack("NnnnnN")
      ary[2] = (ary[2] & 0x0FFF) | (5 << 12)
      ary[3] = (ary[3] & 0x3FFF) | 0x8000

      "%08x-%04x-%04x-%04x-%04x%08x" % ary
    end
  end
end
