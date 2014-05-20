require 'openssl'
require 'yaml'

credentials = YAML.load_file 'credentials.yml'
key = YAML.load_file 'key.yml'

decipher = OpenSSL::Cipher::AES.new(128, :CBC)
decipher.decrypt
decipher.key = key[:key]
decipher.iv = key[:iv]

data = credentials[:password]

plain = decipher.update(data) + decipher.final

puts plain
