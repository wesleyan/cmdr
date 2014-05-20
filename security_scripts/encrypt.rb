require 'openssl'
require 'highline/import'
require 'yaml'
require 'securerandom'

print 'Enter the name of the user: '
user = gets.chomp

data = '2'
data2 = '1'
notfirst = false
while data != data2
  puts 'Passwords did not match' if notfirst
  data = ask('Enter your password:  ') { |q| q.echo = '*' }
  data2 = ask('Enter your password:  ') { |q| q.echo = '*' }
  notfirst = true
end

aes = OpenSSL::Cipher.new('AES-128-CBC')

key = SecureRandom.hex
iv = aes.random_iv

File.open('key.yml', 'wb') do |file|
  file.write({ key: key, iv: iv }.to_yaml)
end

File.open('iv', 'wb') do |file|
  file.write(iv)
end

aes.encrypt
aes.key = key
aes.iv = iv

enc = aes.update(data) + aes.final
File.open('credentials.yml', 'wb') do |file|
  file.write({ user: user, password: enc }.to_yaml)
end
