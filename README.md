[![wercker status](https://app.wercker.com/status/324d9f36b06c877d9f2df4e26489b8bd/s/master "wercker status")](https://app.wercker.com/project/bykey/324d9f36b06c877d9f2df4e26489b8bd)

[![Build Status](https://magnum.travis-ci.com/croeck/paasal.svg?token=4rnK13d2FLuvMVhBBFCH&branch=master)](https://magnum.travis-ci.com/croeck/paasal)
[![Dependency Status](https://gemnasium.com/847585fdbecac653f6cfbd0a301b2f0f.svg)](https://gemnasium.com/croeck/paasal)
[![Code Climate](https://codeclimate.com/repos/54af9232695680520400157d/badges/d9c8c6bf17955025db7a/gpa.svg)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
[![Test Coverage](https://codeclimate.com/repos/54af9232695680520400157d/badges/d9c8c6bf17955025db7a/coverage.svg)](https://codeclimate.com/repos/54af9232695680520400157d/feed)

# PaaSal

_PaaSal_ is a RESTful abstraction layer for the management functions of Platform-as-a-Service (PaaS) providers.  
The API is build using [Ruby](https://www.ruby-lang.org) and the [grape framework](https://github.com/intridea/grape). It provides fully compliant [swagger](http://swagger.io/) schemas that serve for documentation and client generation.

## Use in your application

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


## Use the API

Besides including the abstraction layer in your application, PaaSal can also be started and serve the RESTful API:

#### Start a `rack` server
A rack server can be started in multiple ways.
The most convinient solution is to use the provided script:  

	./bin/paasal start 

Hower, you can also start the API using another rack compliant server, e.g. [thin](http://code.macournoyer.com/thin/) or rely on your default rack server:

    rackup

#### API endpoints

TODO

## Configuration

TODO



## API client(s)

As of now, there is no API client available.
As a reward of providing swagger-compatible API docs, clients can be generated for several languages:
`Scala`, `Flash`, `Java`, `Objc`, `PHP`, `Python`, `Python3`, `Ruby`

For detailed information, please have a look at the [swagger-codegen project](https://github.com/swagger-api/swagger-codegen).

### Accept Header

Paasal always uses the latest API version if no `Accept` header is specified.
We therefore **strongly encourage** you to always specify the `Accept` header.
The vendor thereby must be set to `paasal` and the version must be available.
Otherwise an error with the HTTP status `406` is returned.
A sample `Accept` header would be:

    Accept = application/vnd.paasal-v1

## Tests

The tests are divided into 3 categories, _unit_, _integration_ and _adapter_ tests.
You can either call all tests or each suite seperately.

##### Invoke

    bundle exec rake spec

### Unit Tests

##### Invoke

    bundle exec rake spec:suite:unit

### Integration Tests

##### Invoke

    bundle exec rake spec:suite:integration

### Adapter Tests

The adapter tests rely on previously recorded interactions with the provider's endpoints. They do not invoke external HTTP requests.
When code changes result in different requests, the interactions have to be re-recorded.

##### Invoke

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
[![Wercker](https://img.shields.io/wercker/ci/324d9f36b06c877d9f2df4e26489b8bd.svg?style=flat-square)](https://app.wercker.com/project/bykey/324d9f36b06c877d9f2df4e26489b8bd)
[![Code Climate](https://img.shields.io/codeclimate/github/croeck/paasal.svg?style=flat-square)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/croeck/paasal.svg?style=flat-square)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
