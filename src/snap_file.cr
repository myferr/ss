require "openssl"
require "digest/sha256"
require "json"

module Ss
  class SnapFile
    property data : Hash(String, JSON::Any)

    ENCRYPTION_KEY = "ss-snapshot-key-12345"

    def initialize(@data)
    end

    def encrypt : String
      cipher = OpenSSL::Cipher.new("aes-256-cbc")
      cipher.encrypt

      key = cipher.key = Digest::SHA256.digest(ENCRYPTION_KEY)
      iv = cipher.random_iv

      json_data = @data.to_json
      encrypted = cipher.update(json_data) + cipher.final

      header = {
        "version" => "1.0",
        "iv" => Base64.strict_encode(iv),
        "timestamp" => Time.utc.to_unix.to_s
      }

      encoded_header = Base64.strict_encode(header.to_json)
      encoded_data = Base64.strict_encode(encrypted)

      "#{encoded_header}.#{encoded_data}"
    end

    def self.decrypt(encrypted_content : String) : Hash(String, JSON::Any)
      header_part, data_part = encrypted_content.split(".")

      header_json = Base64.decode_string(header_part)
      header = Hash(String, JSON::Any).from_json(header_json)

      iv = Base64.decode_string(header["iv"].as_s)
      encrypted_data = Base64.decode_string(data_part)

      decipher = OpenSSL::Cipher.new("aes-256-cbc")
      decipher.decrypt
      decipher.key = Digest::SHA256.digest(ENCRYPTION_KEY)
      decipher.iv = iv

      decrypted = decipher.update(encrypted_data) + decipher.final

      Hash(String, JSON::Any).from_json(String.new(decrypted))
    end
  end
end
