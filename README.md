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

## Get list of Students

### Request

`GET /students/`

    curl -i -H 'Accept: application/json' http://localhost:7000/students/

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:30 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 2

    []

## Create a new Student

### Request

`POST /students/`

    curl -i -H 'Accept: application/json' -d 'registration_number=123456&name=Foo%last_name=Bar&status=new' http://localhost:7000/students

### Response

    HTTP/1.1 201 Created
    Date: Thu, 24 Feb 2011 12:36:30 GMT
    Status: 201 Created
    Connection: close
    Content-Type: application/json
    Location: /students/1
    Content-Length: 36

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"new"}

## Get a specific Student

### Request

`GET /students/id`

    curl -i -H 'Accept: application/json' http://localhost:7000/students/1

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:30 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 36

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"new"}

## Get a non-existent Student

### Request

`GET /students/id`

    curl -i -H 'Accept: application/json' http://localhost:7000/students/9999

### Response

    HTTP/1.1 404 Not Found
    Date: Thu, 24 Feb 2011 12:36:30 GMT
    Status: 404 Not Found
    Connection: close
    Content-Type: application/json
    Content-Length: 35

    {"status":404,"reason":"Not found"}

## Create another new Student

### Request

`POST /students/`

    curl -i -H 'Accept: application/json' -d 'registration_number=654321&name=Bar&last_name=Foo' http://localhost:7000/students

### Response

    HTTP/1.1 201 Created
    Date: Thu, 24 Feb 2011 12:36:31 GMT
    Status: 201 Created
    Connection: close
    Content-Type: application/json
    Location: /student/2
    Content-Length: 35

    {"id":2,"registration_number":654321,"name":"Bar","last_name":"Foo","status":null}

## Get list of Students again

### Request

`GET /students/`

    curl -i -H 'Accept: application/json' http://localhost:7000/students/

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:31 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 74

    [{"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"new"},{"id":2,"registration_number":654321,"name":"Bar","last_name":"Foo","status":null}]

## Change a Student's state

### Request

`PATCH /students/:id/status/changed`

    curl -i -H 'Accept: application/json' -X PATCH http://localhost:7000/students/1/status/changed

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:31 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 40

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"changed"}

## Get changed Student

### Request

`GET /students/id`

    curl -i -H 'Accept: application/json' http://localhost:7000/students/1

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:31 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 40

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"changed"}

## Change a Student

### Request

`PUT /students/:id`

    curl -i -H 'Accept: application/json' -X PUT -d 'name=Foo&status=changed2' http://localhost:7000/students/1

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:31 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 41

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"changed2"}

## Attempt to change a Student using partial params

### Request

`PUT /students/:id`

    curl -i -H 'Accept: application/json' -X PUT -d 'status=changed3' http://localhost:7000/students/1

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:32 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 41

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"changed3"}

## Attempt to change a Student using invalid params

### Request

`PUT /students/:id`

    curl -i -H 'Accept: application/json' -X PUT -d 'id=99&status=changed4' http://localhost:7000/students/1

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:32 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 41

    {"id":1,"registration_number":123456,"name":"Foo","last_name":"Bar","status":"changed4"}

## Change a Student using the _method hack

### Request

`POST /students/:id`

    curl -i -H 'Accept: application/json' -X POST -d 'name=Baz&_method=PUT' http://localhost:7000/students/1

### Response

    HTTP/1.1 200 OK
    Date: Thu, 24 Feb 2011 12:36:32 GMT
    Status: 200 OK
    Connection: close
    Content-Type: application/json
    Content-Length: 41

    {"id":1,"registration_number":123456,"name":"Baz","last_name":"Bar","status":"changed4"}

## Change a Student using the _method hack in the url

### Request

`POST /students/:id?_method=PUT`

    curl -i -H 'Accept: application/json' -X POST -d 'name=Qux' http://localhost:7000/students/1?_method=PUT

### Response

    HTTP/1.1 404 Not Found
    Date: Thu, 24 Feb 2011 12:36:32 GMT
    Status: 404 Not Found
    Connection: close
    Content-Type: text/html;charset=utf-8
    Content-Length: 35

    {"id":1,"registration_number":123456,"name":"Qux","last_name":"Bar","status":"changed4"}

## Delete a Student

### Request

`DELETE /students/id`

    curl -i -H 'Accept: application/json' -X DELETE http://localhost:7000/students/1/

### Response

    HTTP/1.1 204 No Content
    Date: Thu, 24 Feb 2011 12:36:32 GMT
    Status: 204 No Content
    Connection: close


## Try to delete same Student again

### Request

`DELETE /students/id`

    curl -i -H 'Accept: application/json' -X DELETE http://localhost:7000/students/1/

### Response

    HTTP/1.1 404 Not Found
    Date: Thu, 24 Feb 2011 12:36:32 GMT
    Status: 404 Not Found
    Connection: close
    Content-Type: application/json
    Content-Length: 35

    {"status":404,"reason":"Not found"}

## Get deleted Student

### Request

`GET /students/1`

    curl -i -H 'Accept: application/json' http://localhost:7000/students/1

### Response

    HTTP/1.1 404 Not Found
    Date: Thu, 24 Feb 2011 12:36:33 GMT
    Status: 404 Not Found
    Connection: close
    Content-Type: application/json
    Content-Length: 35

    {"status":404,"reason":"Not found"}

## Delete a Student using the _method hack

### Request

`POST /students/id`

    curl -i -H 'Accept: application/json' -X POST -d '_method=DELETE' http://localhost:7000/students/2/

### Response

    HTTP/1.1 204 No Content
    Date: Thu, 24 Feb 2011 12:36:33 GMT
    Status: 204 No Content
    Connection: close

## Get supported HTTP methods

### Request

`OPTIONS /students/`

    curl -i -H 'Accept: application/json' -X OPTIONS http://localhost:7000/students

### Response

    HTTP/1.1 200 OK
    Date: Fri, 17 Apr 2015 04:33:37 GMT
    Status: 200 OK
    Connection: close
    Content-Type: text/html;charset=utf-8
    Allow: GET, POST, PUT, PATCH, DELETE, OPTIONS
    X-XSS-Protection: 1; mode=block
    X-Content-Type-Options: nosniff
    X-Frame-Options: SAMEORIGIN
    Transfer-Encoding: chunked

    Content-TypeAllowX-XSS-ProtectionX-Content-Type-OptionsX-Frame-OptionsTransfer-Encoding
