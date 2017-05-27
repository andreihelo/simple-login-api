#encoding:utf-8

# SIMPLE LOGIN API example
# - manages single resource called User.
# - all results (including error messages) returned as JSON (Accept header)

## requires
require 'sinatra'
require 'json'
require 'time'
require 'pp'

### datamapper requires
require 'data_mapper'
require 'dm-types'
require 'dm-timestamps'
require 'dm-validations'

## model
### helper modules
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
end

### Student
class Student
  include DataMapper::Resource
  include StandardProperties
  extend Validations

  property :registration_number, Integer, :required => true
  property :name, String, :required => true
  property :last_name, String, :required => true
  property :status, String

  validates_length_of :registration_number, :equals => 6
end

## set up db
env = ENV["RACK_ENV"]
puts "RACK_ENV: #{env}"
if env.to_s.strip == ""
  abort "Must define RACK_ENV"
end

DataMapper.setup(:default, ENV["RESTFUL_API_DATABASE_URL"])

## create schema if necessary
DataMapper.auto_upgrade!

## logger
def logger
  @logger ||= Logger.new(STDOUT)
end

## UserResource application
class UserResource < Sinatra::Base
  set :methodoverride, true

  ## helpers
  def self.put_or_post(*a, &b)
    put *a, &b
    post *a, &b
  end

  helpers do
    def json_status(code, reason)
      status code
      {
        :status => code,
        :reason => reason
      }.to_json
    end

    def accept_params(params, *fields)
      h = { }
      fields.each do |name|
        h[name] = params[name] if params[name]
      end
      h
    end
  end

  ## GET /students - return all students
  get "/students/?", :provides => :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    if students = Student.all
      students.to_json
    else
      json_status 404, "Not found"
    end
  end

  ## GET /students/:id - return student with specified id
  get "/students/:id", :provides => :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    # check that :id param is an integer
    if Student.valid_id?(params[:id])
      if student = Student.first(:id => params[:id].to_i)
        student.to_json
      else
        json_status 404, "Not found"
      end
    else
      # TODO: find better error for this (id not an integer)
      json_status 404, "Not found"
    end
  end

  ## POST /students/ - create new student
  post "/students/?", :provides => :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    new_params = accept_params(params, :registration_number, :name, :last_name, :status)
    student = Student.new(new_params)

    if student.save
      headers["Location"] = "/students/#{student.id}"
      # http://www.w3.org/Protocols/rfc2616/rfc2616-sec9.html#sec9.5
      status 201 # Created
      student.to_json
    else
      json_status 400, student.errors.to_hash
    end
  end

  ## PATCH /students/:id/:status - change a student's status
  patch "/students/:id/status/:status", :provides => :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    if Student.valid_id?(params[:id])
      if student = Student.first(:id => params[:id].to_i)
        student.status = params[:status]
        if student.save
          student.to_json
        else
          json_status 400, student.errors.to_hash
        end
      else
        json_status 404, "Not found"
      end
    else
      json_status 404, "Not found"
    end
  end

  ## PUT /students/:id - change or create a student
  put_or_post "/students/:id", :provides => :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    new_params = accept_params(params, :registration_number, :name, :last_name, :status)

    if Student.valid_id?(params[:id])
      if student = Student.first_or_create(:id => params[:id].to_i)
        student.attributes = student.attributes.merge(new_params)
        if student.save
          student.to_json
        else
          json_status 400, student.errors.to_hash
        end
      else
        json_status 404, "Not found"
      end
    else
      json_status 404, "Not found"
    end
  end

  ## DELETE /students/:id - delete a specific student
  delete "/students/:id/?", :provides => :json do
    content_type :json
    response['Access-Control-Allow-Origin'] = '*'

    if student = Student.first(:id => params[:id].to_i)
      student.destroy!
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
      json_status 404, "Not found"
    end
  end

  options "/students" do
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, POST, PUT, PATCH, DELETE, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Allow'
    status 200
    headers "Allow" => "GET, POST, PUT, PATCH, DELETE, OPTIONS"
  end

  ## misc handlers: error, not_found, etc.
  get "*" do
    status 404
  end

  put_or_post "*" do
    status 404
  end

  delete "*" do
    status 404
  end

  not_found do
    json_status 404, "Not found"
  end

  error do
    json_status 500, env['sinatra.error'].message
  end
end
