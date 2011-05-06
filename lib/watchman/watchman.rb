require 'sinatra/base'
require 'watchman/repository'
require 'watchman/environment'

module Watchman
  class Server < Sinatra::Base
    def initialize
      @ruleset = Repository.download :default
      @ruleset.start
      run! 
    end

    def self.secure(method, url, &block)

    end

    def self.secure_get(url, &block)
      self.secure :get, url, &block
    end

    def self.secure_post(url, &block)
      self.secure :post, url, &block
    end

    get '/rulesets/list' do
      Repository.list
    end

    get '/interface/list' do
      Repository.list
    end

    get '/behaviors/list' do
      @env.behaviors.to_s
    end

    get '/states/list' do
      @env.states.to_s
    end

    get '/tests/list' do
      @env.tests.to_s
    end

    post '/rulesets/set/:rs' do
      new_ruleset = Repository.download params[:rs]
      @ruleset.stop
      @ruleset = new_ruleset
      env.start
    end

    get '/environment/rules' do
      @ruleset.rules
    end

    post '/behaviors/add/:command' do
      if `#{params[:command]}`
        add_behavior do
          `#{params[:command]}`
        end
      end
    end

    post '/behaviors/delete/:name' do
      delete_behavior params[:name]
    end

    get '/env/sample/:behavior' do
      @env.behavior(params[:behavior]).sample! 
    end

    get '/env/state/:name' do
      @ruleset.state_of? params[:state]
    end

    post '/tests/run/:desc' do
      if Test.new(params[:desc]).run
        "true"
      else
        "false"
      end
    end

    #tab-completion
    get '/complete/:text' do
      term_space = [@env.behaviors, @env.states, @env.rules] 
      terms = term_space.flatten.collect {|t| t.to_s }
    end
  end
end

