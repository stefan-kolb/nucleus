[![Build Status](https://magnum.travis-ci.com/croeck/paasal.svg?token=4rnK13d2FLuvMVhBBFCH&branch=master)](https://magnum.travis-ci.com/croeck/paasal)
[![Dependency Status](https://gemnasium.com/847585fdbecac653f6cfbd0a301b2f0f.svg)](https://gemnasium.com/croeck/paasal)
[![Code Climate](https://codeclimate.com/repos/54af9232695680520400157d/badges/d9c8c6bf17955025db7a/gpa.svg)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
[![Test Coverage](https://codeclimate.com/repos/54af9232695680520400157d/badges/d9c8c6bf17955025db7a/coverage.svg)](https://codeclimate.com/repos/54af9232695680520400157d/feed)

# PaaSal

_PaaSal_ is a RESTful abstraction layer to achieve unified deployment and management functions of Platform-as-a-Service (PaaS) providers.  
The API is build using [Ruby](https://www.ruby-lang.org) and the [grape framework](https://github.com/intridea/grape). It provides fully compliant [swagger](http://swagger.io/) schemas that serve for documentation and client generation.

PaaSal differs between Vendor, Providers and Endpoints.
A *Vendor* is the organziation that developed the platform.
The *Provider* runs the platform, which always has at least one *Endpoint*, but can also have multiple endpoints for different regions.

## Table of Contents

* [Supported Vendors](#supported-vendors)
* [Usage](#usage)
  * [Use in your application](#use-in-your-application)
  * [Use the API](#use-the-api)
      * [Start the server:](#start-the-server:)
    * [API endpoints](#api-endpoints)
* [Functionality](#functionality)
* [Configuration](#configuration)
  * [Vendors, Providers and Endpoints](#vendors,-providers-and-endpoints)
  * [Application configuration](#application-configuration)
* [API client(s)](#api-clients)
  * [Accept Header](#accept-header)
  * [Language specific clients](#language-specific-clients)
* [Tests](#tests)
  * [Unit Tests](#unit-tests)
  * [Integration Tests](#integration-tests)
  * [Adapter Tests](#adapter-tests)
    * [Recording](#recording)
      * [Missing or invalid VCR recording](#missing-or-invalid-vcr-recording)
      * [Sensitive data](#sensitive-data)
* [Schema validation](#schema-validation)
* [Versioning](#versioning)
* [Contributing](#contributing)

## Supported Vendors

- ~~Heroku~~
- ~~CloudFoundry (tested with Stackato and IBM Bluemix)~~
- ~~Openshift 2~~
- ~~CloudControl~~

## Usage

### Use in your application

Add this line to your application's Gemfile:

```ruby
gem 'paasal'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install paasal
    
Finally require the gem in your application

	require 'paasal'


### Use the API

Besides including the abstraction layer in your application, PaaSal can also be started and serve the RESTful API:

#### Start the server:

A rack server can be started in multiple ways.
The most convinient solution is to use the provided script:  

	./bin/paasal start 

Hower, you can also start the API using another rack compliant server, e.g. [thin](http://code.macournoyer.com/thin/) or rely on your default rack server:

    rackup

#### API endpoints

**TODO: add more documentation here, especially examples (!)**

The API of PaaSal is documented by the use of swagger.
After your started a server insatnce, you can access an interactive UI at the `/docs` path.

## Functionality

**TODO: specify what can already be done**

## Configuration

**TODO**

Several parts of PaaSal can be configured, e.g. whether to persist your data or always start with a clean instance.

### Vendors, Providers and Endpoints

A vendor is reflected by an adapter implementation, but the providers and their endpoints can either be changed at runtime or be configured in `.yaml` files. These adapter configuration files are located in the project directory at `config/adapters`.

###### Example adapter configuration, here: Openshift 2

    --- 
    name: "Openshift 2"
    id: "openshift2"
    providers:
      - 
        name: "Openshift Online"
        id: "openshift-online"
        endpoints:
          - 
            name: "Openshift Online"
            id: "openshift-online"
            url: "openshift.redhat.com/broker/rest"
            
### Application configuration

Some aspects, for instance where the server shall save its storage files, can be adjusted.

    # [optional] The available levels are: FATAL, ERROR, WARN, INFO, DEBUG
    configatron.logging.level = Logger::Severity::WARN

    # [optional] Please specify the DB directory if you plan to persist your vendors, providers and their endpoints. Comment-out to use a temporary directory
    # configatron.db.path = '/path/to/the/application/paasal/store/'
    # [optional] If true, the DB will be deleted when the server is being closed.
    # configatron.db.delete_on_shutdown = false
    # [optional, requires 'configatron.db.path'] If true, the DB will be initialized with default values, which may partially override previously persisted entities. False keeps the changes that were applied during runtime.
    # configatron.db.override = false

	# You can change these values if you host the application and offer access to other users
    configatron.api.title = 'PaaSal - Platform as a Service abstraction layer API'
    configatron.api.description = 'PaaSal allows to manage multiple PaaS providers with just one API to be used'
    configatron.api.contact = 'youremail@example.org'
    # The name of the license.
    configatron.api.license = ''
    # The URL of the license.
    configatron.api.license_url = ''
    # The URL of the API terms and conditions.
    configatron.api.terms_of_service_url = 'API still under development, no guarantees (!)'


## API clients

### REST client

The API can be used with the REST client of your choice.

##### Accept Header

Paasal always uses the latest API version if no `Accept` header is specified.
We therefore **strongly encourage** you to always specify the `Accept` header.
The vendor thereby must be set to `paasal` and the version must be available.
Otherwise an error with the HTTP status `406` is returned.
A sample `Accept` header would be:

    Accept = application/vnd.paasal-v1

##### Error codes

The application uses the following subset of error codes:

    400: Bad Request
    401: Unauthorized
    403: Forbidden
    404: Resource not found
    406: API vendor or version not found
    422: Unprocessable Entity due to invalid parameters
    500: Internal processing error

All errors are returned in a common schema:

    {
      "status": HTTP_STATUS_CODE,
      "message": SIMPLE_ERROR_MESSAGE,
      "dev_message": DEVELOPER_MESSAGE_WITH_TECHNICAL_DETAILS_TO_RESOLUTION,
      "error_code": UNIQUE_ERROR_CODE,
      "more_info": LINK_TO_DOCUMENTATION_DESCRIBING_THE_ERROR
    }

### Language specific clients

As of now, there is no language specific API client available.
As a reward of providing swagger-compatible API docs, clients can be generated for several languages:
`Scala`, `Flash`, `Java`, `Objc`, `PHP`, `Python`, `Python3`, `Ruby`

For detailed information, please have a look at the [swagger-codegen project](https://github.com/swagger-api/swagger-codegen).



## Tests

The tests are divided into 3 categories, _unit_, _integration_ and _adapter_ tests.
You can either call all tests or each suite seperately.

**Invoke:**

    bundle exec rake spec

### Unit Tests

**Invoke:**

    bundle exec rake spec:suite:unit

### Integration Tests

**Invoke:**

    bundle exec rake spec:suite:integration

### Adapter Tests

The adapter tests rely on previously recorded interactions with the provider's endpoints. They do not invoke external HTTP requests.
When code changes result in different requests, the interactions have to be re-recorded.

**Invoke:**

    bundle exec rake spec:suite:adapters

##### Recording

Recording new VCR cassettes requires you to have an account at the platform that shall be recorded.
The credentials must be specified in the `config/.credentials` file.

The file is ignored and shall _never_ be committed. It must use the following syntax:

    heroku:
      user:     'my_heroku_username'
      password: 'my_heroku_usernames_password'
      
To record the interactions, you only have to call the Rake `record` task, eg. by calling: `bundle exec rake record`

###### Missing or invalid VCR recording
If the recorded cassette is invalid due to a recent change, the test that use this cassette are going to fail.

###### Sensitive data
Most of the requests contain sensitive data that we do not want to be included in the recorded cassettes.
By implementation, the API tokens and **all** data that is specified in the `config/.credentials` file are filtered.

## Schema validation

The generated schema can be validated against the [swagger specification](https://github.com/swagger-api/swagger-spec).
Please have a look at the [swagger-codegen project](https://github.com/swagger-api/swagger-codegen).

## Versioning

PaaSal follows the [Semantic Versioning](http://semver.org/) standard.
Therefore, PaaSal also allows to serve multiple versions of the API and provide legacy support.

However, be aware that
__each non-backward compatible change of the application must result in an increase of the major version.__

The initial version is: `0.1.0`.

## Contributing

Everyone is welcome to contribute via

- Forks & Pull Requests
- Issues
- Emails
- Anything that comes into your mind ;-)

## shield.io badges (not working)

[![Build Status](https://img.shields.io/travis/croeck/paasal.svg?style=flat-square&token=4rnK13d2FLuvMVhBBFCH)](https://magnum.travis-ci.com/croeck/paasal)
[![Gem Version](http://img.shields.io/gem/v/paasal.svg?style=flat-square)](http://badge.fury.io/rb/paasal)
[![Dependency Status](https://img.shields.io/gemnasium/croeck/paasal.svg?style=flat-square)](https://gemnasium.com/croeck/paasal)
[![Code Climate](https://img.shields.io/codeclimate/github/croeck/paasal.svg?style=flat-square)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/croeck/paasal.svg?style=flat-square)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
