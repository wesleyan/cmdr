require 'yaml'
require 'openssl'
module Authenticate
  def Authenticate.get_credentials(path="/var/cmdr-daemon")
    YAML::ENGINE::yamler = 'syck'

    credentials = YAML::load_file "#{path}/credentials.yml"
    key = YAML::load_file "#{path}/key.yml"

    decipher = OpenSSL::Cipher::AES.new(128, :CBC)
    decipher.decrypt
    decipher.key = key["key"]
    decipher.iv = key["iv"]

    pw = decipher.update(credentials["password"]) + decipher.final
    auth = {"user" => credentials["user"], "password" => pw}
  end
end
