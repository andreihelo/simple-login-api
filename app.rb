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

require 'pry'

##   Model
###  Helper modules
#### StandardProperties
module StandardProperties
  def self.included(other)
    other.class_eval do
      property :id, other::Serial
      # property :created_at, DateTime
      # property :updated_at, DateTime
    end
  end
end

#### Validations
module Validations
  def valid_id?(id)
    id && id.to_s =~ /^\d+$/
  end
  #
  # def valid_password?(password, password_confirmation)
  #   password === password_confirmation
  # end
end

### User
class User
  include DataMapper::Resource
  include StandardProperties
  extend  Validations

  property :token,                 String
  property :username,              String, required: true
  property :first_name,            String, required: true
  property :last_name,             String, required: true
  property :password,              String, required: true
  property :password_confirmation, String, required: true

  validates_length_of   :password,              min: 6
  validates_length_of   :password_confirmation, min: 6
  validates_with_method :password, method: :password_confirmation_matches?

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

  ## POST /signup - Create new user
  post '/signup/?', provides: :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    new_params = accept_params(params, :username, :first_name, :last_name, :password, :password_confirmation)
    new_params.merge!(token: SecureRandom.uuid)
    user       = User.new(new_params)

    if user.save
      headers['Location'] = "/users/#{user.token}"
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.5
      status 201 # Created
      user.to_json(exclude: [:id])
    else
      json_status 400, user.errors.to_hash
    end
  end

  # ## GET /students/:id - return user with specified id
  # get "/students/:id", :provides => :json do
  #   content_type :json
  #   response['Access-Control-Allow-Origin'] = '*'
  #
  #   # check that :id param is an integer
  #   if User.valid_id?(params[:id])
  #     if student = User.first(:id => params[:id].to_i)
  #       student.to_json
  #     else
  #       json_status 404, "Not found"
  #     end
  #   else
  #     # TODO: find better error for this (id not an integer)
  #     json_status 404, "Not found"
  #   end
  # end
  #
  # ## PATCH /students/:id/:status - change a user's status
  # patch "/students/:id/status/:status", :provides => :json do
  #   content_type :json
  #   response['Access-Control-Allow-Origin'] = '*'
  #
  #   if User.valid_id?(params[:id])
  #     if student = User.first(:id => params[:id].to_i)
  #       student.status = params[:status]
  #       if student.save
  #         student.to_json
  #       else
  #         json_status 400, student.errors.to_hash
  #       end
  #     else
  #       json_status 404, "Not found"
  #     end
  #   else
  #     json_status 404, "Not found"
  #   end
  # end
  #
  # ## PUT /students/:id - change or create a user
  # put_or_post "/students/:id", :provides => :json do
  #   content_type :json
  #   response['Access-Control-Allow-Origin'] = '*'
  #
  #   new_params = accept_params(params, :registration_number, :name, :last_name, :status)
  #
  #   if User.valid_id?(params[:id])
  #     if student = User.first_or_create(:id => params[:id].to_i)
  #       student.attributes = student.attributes.merge(new_params)
  #       if student.save
  #         student.to_json
  #       else
  #         json_status 400, student.errors.to_hash
  #       end
  #     else
  #       json_status 404, "Not found"
  #     end
  #   else
  #     json_status 404, "Not found"
  #   end
  # end
  #
  # ## DELETE /students/:id - delete a specific user
  # delete "/students/:id/?", :provides => :json do
  #   content_type :json
  #   response['Access-Control-Allow-Origin'] = '*'
  #
  #   if student = User.first(:id => params[:id].to_i)
  #     student.destroy!
  #     # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.7
  #     status 204 # No content
  #   else
  #     # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.1.2
  #     # Note: section 9.1.2 states:
  #     #   Methods can also have the property of "idempotence" in that
  #     #   (aside from error or expiration issues) the side-effects of
  #     #   N > 0 identical requests is the same as for a single
  #     #   request.
  #     # i.e that the /side-effects/ are idempotent, not that the
  #     # result of the /request/ is idempotent, so I think it's correct
  #     # to return a 404 here.
  #     json_status 404, "Not found"
  #   end
  # end
  #
  # options "/students" do
  #   response['Access-Control-Allow-Origin']  = '*'
  #   response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
  #   response['Access-Control-Allow-Headers'] = 'Allow'
  #   status 200
  #   headers "Allow" => "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  # end
  
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
