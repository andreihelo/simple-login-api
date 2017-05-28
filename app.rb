#encoding:utf-8

# SIMPLE LOGIN API example
# - Manages single resource called User.
# - All results (including error messages) returned as JSON (Accept header)

## Requires
require 'sinatra'
require 'json'
require 'time'
require 'pp'
require 'securerandom'

### Datamapper requires
require 'data_mapper'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'

##   Model
###  Helper modules
#### StandardProperties
module StandardProperties
  def self.included(other)
    other.class_eval do
      property :id, other::Serial
    end
  end
end

#### Validations
module Validations
  def valid_id?(id)
    id && id.to_s =~ /^\d+$/
  end
end

### User
class User
  include DataMapper::Resource
  include StandardProperties
  extend  Validations

  property :token,                 String
  property :username,              String, required: true,
           format: /^[a-z0-9_-]{3,15}$/,
           messages: {format: 'Username should include only downcase letters, numbers, underscore and hyphens'}
  property :first_name,            String, required: true
  property :last_name,             String, required: true
  property :password,              String, required: true
  property :password_confirmation, String, required: true

  validates_uniqueness_of :username
  validates_length_of     :username,              min: 6, max: 15
  validates_length_of     :password,              min: 6
  validates_length_of     :password_confirmation, min: 6
  validates_with_method   :password, method: :password_confirmation_matches?

  def password_confirmation_matches?
    if self.password === self.password_confirmation
      return true
    else
      [false, 'Password and password confirmation doesn\'t matches']
    end
  end
end

## Set up DB
env = ENV['RACK_ENV']
puts "RACK_ENV: #{env}"
if env.to_s.strip == ''
  abort 'Must define RACK_ENV'
end

DataMapper.setup(:default, ENV['SIMPLE_LOGIN_API_DATABASE_URL'])

## Create schema if necessary
DataMapper.auto_upgrade!

## Logger
def logger
  @logger ||= Logger.new(STDOUT)
end

## UserResource application
class UserResource < Sinatra::Base
  set :methodoverride, true

  ## Helpers
  def self.put_or_post(*a, &b)
    put  *a, &b
    post *a, &b
  end

  helpers do
    def json_status(code, reason)
      status code
      {
        status: code,
        reason: reason
      }.to_json
    end

    def accept_params(params, *fields)
      h = {}
      fields.each do |name|
        h[name] = params[name] if params[name]
      end
      h
    end
  end

  ## POST /signup - Create a new user
  post '/signup', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    new_params = accept_params(params, :username, :first_name, :last_name, :password, :password_confirmation)
    user       = User.new(new_params)

    if user.save
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.5
      status 201 # Created
      user.to_json(exclude: [:id, :token, :password, :password_confirmation])
    else
      json_status 400, user.errors.to_hash
    end
  end

  ## POST /signin - Login an existing user
  post '/signin', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    new_params = accept_params(params, :username, :password)

    if user = User.first(username: new_params[:username], password: new_params[:password])
      user.update!(token: SecureRandom.uuid)
      user.to_json(exclude: [:id, :password, :password_confirmation])
    else
      json_status 401, 'Invalid credentials'
    end
  end

  ## GET /profile/:token - Return user with specified token
  get '/profile/:token', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    if user = User.first(token: params[:token])
      user.to_json(exclude: [:id, :password_confirmation])
    else
      json_status 404, 'Not found'
    end
  end

  ## PUT /profile/:token - Change user attributes
  put_or_post '/profile/:token', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    new_params = accept_params(params, :first_name, :last_name, :password, :password_confirmation)

    if user = User.first(token: params[:token])
      user.attributes = user.attributes.merge(new_params)
      if user.save
        user.to_json(exclude: [:id, :password_confirmation])
      else
        json_status 400, user.errors.to_hash
      end
    else
      json_status 404, 'Not found'
    end
  end

  ## DELETE /signout/:token - Signout a specific user
  delete '/signout/:token', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    if user = User.first(token: params[:token])
      user.update!(token: nil)
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.7
      status 204 # No content
    else
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.2
      # Note: section 9.1.2 states:
      #   Methods can also have the property of "idempotence" in that
      #   (aside from error or expiration issues) the side-effects of
      #   N > 0 identical requests is the same as for a single
      #   request.
      # i.e that the /side-effects/ are idempotent, not that the
      # result of the /request/ is idempotent, so I think it's correct
      # to return a 404 here.
      json_status 404, 'Not found'
    end
  end

  ## DELETE /profile/:token - Delete a specific user
  delete '/profile/:token', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    if user = User.first(token: params[:token])
      user.destroy!
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.7
      status 204 # No content
    else
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.2
      # Note: section 9.1.2 states:
      #   Methods can also have the property of "idempotence" in that
      #   (aside from error or expiration issues) the side-effects of
      #   N > 0 identical requests is the same as for a single
      #   request.
      # i.e that the /side-effects/ are idempotent, not that the
      # result of the /request/ is idempotent, so I think it's correct
      # to return a 404 here.
      json_status 404, 'Not found'
    end
  end
  
  ## Misc handlers: error, not_found, etc.
  get '*' do
    status 404
  end

  put_or_post '*' do
    status 404
  end

  delete '*' do
    status 404
  end

  not_found do
    json_status 404, 'Not found'
  end

  error do
    json_status 500, env['sinatra.error'].message
  end
end
