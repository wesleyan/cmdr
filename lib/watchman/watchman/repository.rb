REPOSITORY_URL = ''
ENVIRONMENT_DIR = '~/environments'

class Repository
  def connect
    
  end
  
  def self.after_connecting(name, &block)
    connect
    self.class.define_method(name, lambda {
                               if not @connected
                                 connect
                                 block.call
                               end
                               } )
  end

  after_connecting :list do
    `cd #{ENVIRONMENT_DIR} && wget #{REPOSITORY_URL}/list`
    `cat #{ENVIRONMENT_DIR}/list`.split
  end

  after_connecting :exists? do |env|
    list().include?(env)
  end

  after_connecting :download do |env|
    if env == :default
      `cd #{ENVIRONMENT_DIR} && wget #{REPOSITORY_URL}/default`
    else
      if exists?(env)
      `cd #{ENVIRONMENT_DIR} && wget #{REPOSITORY_URL}/repo/#{env.name}`
      end
    end
  end

  after_connecting :upload do |env|
  end
end
