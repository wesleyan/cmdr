require 'sinatra/base'

class Watchman < Sinatra::Base
  def initialize
    @current = Repository.download :default
    @current.start
    run! 
  end

  get '/environment/list' do
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

  post '/environment/set/:env' do
    env = Repository.download params[:env]
    @current.stop
    @current = env
    env.start
  end

  get '/environment/rules' do
    @current.rules
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
    @current.sample! params[:behavior]
  end

  get '/env/state/:name' do
    @current.state_of? params[:state]
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
    term_space = [@current.behaviors, @current.states, @current.rules] 
    terms = term_space.flatten.collect {|t| t.to_s }
  end
end

