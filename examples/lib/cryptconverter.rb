require 'openssl'

module Temporal
  class CryptConverter < Temporal::Client::Converter::Base
    CIPHER = 'aes-256-gcm'.freeze
    GCM_NONCE_SIZE = 12
    GCM_TAG_SIZE = 16

    METADATA_KEY_ID_KEY = 'encryption-key-id'.freeze
    METADATA_ENCODING_KEY = 'encoding'.freeze
    METADATA_ENCODING = 'binary/encrypted'.freeze

    def to_payloads(data)
      key_id = get_key_id
      key = get_key(key_id)

      payloads = super(data)

      Temporal::Api::Common::V1::Payloads.new(
        payloads: payloads.payloads.map { |payload| encrypt_payload(payload, key_id, key) }
      )
    end

    def from_payloads(payloads)
      return nil if payloads.nil?

      payloads.payloads.map do |payload|
        if payload.metadata[METADATA_ENCODING_KEY] == METADATA_ENCODING
          payload = decrypt_payload(payload)
        end
        from_payload(payload)
      end
    end

    private

    def get_key_id
      'test'
    end

    def get_key(_key_id)
      "test-key-test-key-test-key-test!".b
    end

    def encrypt(data, key)
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.encrypt

      cipher.key = key
      iv = cipher.random_iv

      crypt = cipher.update(data) + cipher.final

      iv + crypt + cipher.auth_tag
    end

    def encrypt_payload(payload, key_id, key)
      Temporal::Api::Common::V1::Payload.new(
        metadata: {
          METADATA_ENCODING_KEY => METADATA_ENCODING,
          METADATA_KEY_ID_KEY => key_id,
        },
        data: encrypt(Temporal::Api::Common::V1::Payload.encode(payload), key)
      )
    end

    def decrypt(data, key)
      cipher = OpenSSL::Cipher.new(CIPHER)
      cipher.decrypt

      cipher.key = key
      cipher.iv = data[0, GCM_NONCE_SIZE]
      cipher.auth_tag = data[-GCM_TAG_SIZE, GCM_TAG_SIZE]

      cipher.update(data[GCM_NONCE_SIZE...-GCM_TAG_SIZE]) + cipher.final
    end

    def decrypt_payload(payload)
      key_id = payload.metadata[METADATA_KEY_ID_KEY]

      unless key_id
        raise "Unable to decrypt payload, no encryption key id"
      end

      key = get_key(key_id)
      serialized_payload = decrypt(payload.data, key)

      Temporal::Api::Common::V1::Payload.decode(serialized_payload)
    end
  end
end
