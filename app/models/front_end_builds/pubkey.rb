require 'front_end_builds/utils/ssh_pubkey_convert'
require 'base64'
require 'openssl'

module FrontEndBuilds
  class Pubkey < ActiveRecord::Base
    validates :name, presence: true
    validates :pubkey, presence: true

    def fingerprint
      content = pubkey.split(/\s/)[1]

      if content
        Digest::MD5.hexdigest(Base64.decode64(content))
          .scan(/.{1,2}/)
          .join(":")
      else
        'Unknown'
      end
    end

    def ssh_pubkey?
      (type, b64, _) = pubkey.split(/\s/)
      %w{ssh-rsa ssh-dss}.include?(type) && b64.present?
    end

    # Public: In order to verify a signature we need the key to be an OpenSSL
    # RSA PKey and not a string that you would find in an ssh pubkey key. Most
    # people are going to be adding ssh public keys to their build system, this
    # method will covert them to OpenSSL RSA if needed.
    def to_rsa_pkey
      FrontEndBuilds::Utils::SSHPubKeyConvert
        .convert(pubkey)
    end

    # Public: Will verify that the sigurate has access to deploy the build
    # object. The signature includes the endpoint and app name.
    #
    # Returns boolean
    def verify(build)
      # TODO might as well cache this and store in the db so we dont have to
      # convert every time
      pkey = to_rsa_pkey
      signature = Base64.decode64(build.signature)
      digest = OpenSSL::Digest::SHA256.new
      expected = "#{build.app.name}-#{build.endpoint}"

      pkey.verify(digest, signature, expected)
    end

    def serialize
      {
        id: id,
        name: name,
        fingerprint: fingerprint
      }
    end
  end
end
