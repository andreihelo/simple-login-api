# SIMPLE LOGIN API example application

This is a bare-bones example of a Sinatra application providing a REST
API to a DataMapper-backed model.

The entire application is contained within the `app.rb` file.

`config.ru` is a minimal Rack configuration for unicorn.

## Install

    bundle install

## Run the app

    unicorn -p 7000

# SIMPLE LOGIN API

The SIMPLE LOGIN API to the example app is described below.

## Create a new User

### Request

`POST /signup/`

    curl -i -H 'Accept: application/json' -X POST -d 'username=foobar&first_name=Foo&last_name=Bar&password=123456&password_confirmation=123456' http://localhost:7000/signup

### Response

    HTTP/1.1 201 Created
    Date: Thu, 27 May 2017 12:36:30 GMT
    Status: 201 Created
    Connection: close
    Content-Type: application/json
    Content-Length: 36

    {"username":"foobar","first_name":"Foo","last_name":"Bar"}

## Login an existing User

### Request

`POST /signin/`

    curl -i -H 'Accept: application/json' -X POST -d 'username=foobar&password=123456' http://localhost:7000/signin

### Response

    HTTP/1.1 200 OK
    Date: Thu, 27 May 2017 12:36:30 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 36

    {"token":"d9ffc44a-529c-4af5-8e67-cf452425b55b",username":"foobar","first_name":"Foo","last_name":"Bar"}

## Return User with specified token

### Request

`GET /profile/:token`

    curl -i -H 'Accept: application/json' http://localhost:7000/profile/d9ffc44a-529c-4af5-8e67-cf452425b55b

### Response

    HTTP/1.1 200 OK
    Date: Thu, 27 May 2017 12:36:30 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 36

    {"token":"d9ffc44a-529c-4af5-8e67-cf452425b55b","username":"foobar","first_name":"Foo","last_name":"Bar","password":"123456"}

## Change User attributes

### Request

`PUT  /profile/:token`
`POST /profile/:token`

Allow to change the next attributes:

- first_name
- last_name
- password
- password_confirmation


    curl -i -H 'Accept: application/json' -X PUT -d 'first_name=Baz' http://localhost:7000/profile/d9ffc44a-529c-4af5-8e67-cf452425b55b
    curl -i -H 'Accept: application/json' -X POST -d 'first_name=Baz' http://localhost:7000/profile/d9ffc44a-529c-4af5-8e67-cf452425b55b

### Response

    HTTP/1.1 200 OK
    Date: Thu, 27 May 2017 12:36:30 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 41

    {"token":"d9ffc44a-529c-4af5-8e67-cf452425b55b","username":"foobar","first_name":"Baz","last_name":"Bar","password":"123456"}

## Signout a specific User

### Request

`DELETE /signout/:token`

    curl -i -H 'Accept: application/json' -X DELETE http://localhost:7000/signout/d9ffc44a-529c-4af5-8e67-cf452425b55b

### Response

    HTTP/1.1 204 No Content
    Date: Thu, 27 May 2017 12:36:30 GMT
    Status: 204 No Content
    Connection: close

## Delete a specific user

### Request

`DELETE /profile/:token`

    curl -i -H 'Accept: application/json' -X DELETE http://localhost:7000/profile/d9ffc44a-529c-4af5-8e67-cf452425b55b

### Response

    HTTP/1.1 204 No Content
    Date: Thu, 27 May 2017 12:36:30 GMT
    Status: 204 No Content
    Connection: close
