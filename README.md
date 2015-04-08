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

* [Ruby Interpreter Compatibility](#ruby-interpreter-compatibility)
* [Supported Vendors](#supported-vendors)
* [Usage](#usage)
  * [Use in your application](#use-in-your-application)
  * [Use the API](#use-the-api)
    * [Start the server](#start-the-server)
    * [API endpoints](#api-endpoints)
* [Functionality](#functionality)
  * [Authentication](#authentication)
    * [Special characters (umlauts, ....)](#special-characters-(umlauts,-....))
  * [Core constructs](#core-constructs)
    * [Vendors](#vendors)
    * [Providers](#providers)
      * [List all providers that are registered for a vendor's platform:](#list-all-providers-that-are-registered-for-a-vendor's-platform:)
      * [Register new provider](#register-new-provider)
    * [Endpoints](#endpoints)
      * [List all endpoints that are registered for a provider](#list-all-endpoints-that-are-registered-for-a-provider)
      * [Register new endpoint](#register-new-endpoint)
  * [Native calls (experimental)](#native-calls-(experimental))
    * [Execute a native API call against the endpoint](#execute-a-native-api-call-against-the-endpoint)
    * [Execute a native API call against an endpoint's application](#execute-a-native-api-call-against-an-endpoint's-application)
* [Configuration](#configuration)
  * [Vendors, Providers and Endpoints](#vendors,-providers-and-endpoints)
  * [Application configuration](#application-configuration)
* [API client(s)](#api-clients)
  * [Accept Header](#accept-header)
  * [Language specific clients](#language-specific-clients)
* [Adapters](#adapters)
  * [Heroku](#heroku)
  * [Cloud Foundry v2](#cloud-foundry-v2)
  * [Openshift v2](#openshift-v2)
  * [cloudControl](#cloudControl)
* [Tests](#tests)
  * [Unit Tests](#unit-tests)
  * [Integration Tests](#integration-tests)
  * [Adapter Tests](#adapter-tests)
    * [Recording](#recording)
      * [Missing or invalid VCR recording](#missing-or-invalid-vcr-recording)
      * [Sensitive data](#sensitive-data)
* [Schema validation](#schema-validation)
* [Versioning](#versioning)
* [Project structure](#project-structure)
* [Contributing](#contributing)
  * [Add a new vendor](#add-a-new-vendor)
  * [Add a vendor version](#add-a-vendor-version)
* [Further documentation](#further-documentation)
* [License](#license)

## Ruby Interpreter Compatibility

PaaSal has been tested on the following ruby interpreters:

- MRI 1.9.3
- MRI 2.0.0
- MRI 2.1.3
- MRI 2.2.1

The CI tests cover all above versions.
Additionally, manual tests were executed on Windows and MAC OS X using MRI 2.1.3

**PaaSal currently won't work on JRuby**

## Supported Vendors

- Heroku
- CloudFoundry
- ~~Openshift 2~~
- ~~CloudControl~~

## Usage

### Use in your application

#### Require paasal and mark as dependency

Add this line to your application's Gemfile:

```ruby
gem 'paasal'
```

And then execute:

```shell
$ bundle
```

Or install it yourself as:

```shell
$ gem install paasal
```
    
Finally require the gem in your application

```ruby
require 'paasal'
```

#### Communicate with an endpoint

**TODO: simplify this approach. User does not have to know about app_domain. Find a way to utilize the config here.**

First, we need to acquire an adapter instance. Choose between one of the following classes:
`Paasal::Adapters::V1::CloudControl`,
`Paasal::Adapters::V1::CloudFoundryV2`,
`Paasal::Adapters::V1::Heroku`,
`Paasal::Adapters::V1::OpenshiftV2`

Initialize the adapter with the parameters:

```ruby
# endpoint_url --> the API endpoint that shall be used, e.g. api.eu-gb.bluemix.net
# endpoint_app_domain --> domain where all apps are available by default, e.g. {app_name}.herokuapps.com
# check_certificates --> Boolean, false causes to trust all SSL certificates and skip their validation
adapter = Paasal::Adapters::V1::CloudFoundryV2.new(endpoint_url, endpoint_app_domain, check_certificates)
```

Fire and forget, or: Invoke your actions

```ruby
# get information about an application
adapter.application(application_id)
```

Check the **documentation** for a complete list of the supported actions.
Refer to the documentation of the REST interface to get detailed information about the parameter options of `post` and `put` commands.

### Use the API

Besides including the abstraction layer in your application, PaaSal can also be started and serve the RESTful API:

#### Start the server

A rack server can be started in multiple ways.
The most convinient solution is to use the provided script:  

```shell
./bin/paasal start
```

Hower, you can also start the API using another rack compliant server, e.g. [thin](http://code.macournoyer.com/thin/) or rely on your default rack server:

```
rackup
```

#### API endpoints

**TODO: add more documentation here, especially examples (!)**

The API of PaaSal is documented by the use of swagger.
After your started a server insatnce, you can access an interactive UI at the `/docs` path.

## Functionality

**TODO: specify what can already be done**

### Authentication

Authentication against the endpoint is managed by PaaSal.
The credentials must be provided as `Basic authentication` header **within each single request**.

```
Authorization: Basic thebase64encodedcredentialsstring
```

#### Special characters (umlauts, ....)

The usage of special characters, for instance the german umlauts as ä, ö and ü may cause issues with some platforms.
Please make sure to select the correct encoding for your credentials before encoding them with base64:

Provider | Encoding | Known issues
:--|:-:|:--
heroku||
cf-stackato|utf-8|Different encodings cause the requests to crash and return status 500

### Core constructs

Vendors, Providers, Endpoints

**TODO: explain what is behind it**

All changes made to these entities at runtime will be discarded, unless you enable the functionality in the configuration and specify a location where to persist the data to.

#### Vendors
You can use the API of PaaSal to show a list of all currently supported vendors.
This request if publicly available and does not require any authentication.

```
GET /api/vendors
```

```json
{
  "size": 4,
  "vendors": [
    {
      "id": "cloudcontrol",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "cloudControl",
      "key": "cloudcontrol",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/vendors/cloudcontrol"
        },
        "parent": {
          "href": "http://localhost:9292/api"
        },
        "providers": {
          "href": "http://localhost:9292/api/vendors/cloudcontrol/providers"
        }
      }
    },
    {
      "id": "cloud_foundry_v2",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "Cloud Foundry V2",
      "key": "cloud_foundry_v2",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/vendors/cloud_foundry_v2"
        },
        "parent": {
          "href": "http://localhost:9292/api"
        },
        "providers": {
          "href": "http://localhost:9292/api/vendors/cloud_foundry_v2/providers"
        }
      }
    },
    {
      "id": "heroku",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "Heroku",
      "key": "heroku",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/vendors/heroku"
        },
        "parent": {
          "href": "http://localhost:9292/api"
        },
        "providers": {
          "href": "http://localhost:9292/api/vendors/heroku/providers"
        }
      }
    },
    {
      "id": "openshift_v2",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "Openshift 2",
      "key": "openshift-2",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/vendors/openshift_v2"
        },
        "parent": {
          "href": "http://localhost:9292/api"
        },
        "providers": {
          "href": "http://localhost:9292/api/vendors/openshift_v2/providers"
        }
      }
    }
  ],
  "_links": {
    "self": {
      "href": "http://localhost:9292/api/vendors"
    },
    "parent": {
      "href": "http://localhost:9292/api"
    }
  }
}
```

You can't create, delete or update a vendor at runtime because they represent the logic to communicate with their platform.

#### Providers

Providers can be managed *without authentication* and support `GET`, `POST`, `PATCH`, `DELETE` requests.

##### List all providers that are registered for a vendor's platform:

```
GET /api/vendors/cloud_foundry_v2/providers
```

```json
{
  "size": 2,
  "providers": [
    {
      "id": "cf-pivotal",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "Pivotal",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/providers/cf-pivotal"
        },
        "parent": {
          "href": "http://localhost:9292/api/vendors/cloud_foundry_v2"
        },
        "endpoints": {
          "href": "http://localhost:9292/api/providers/cf-pivotal/endpoints"
        }
      }
    },
    {
      "id": "bluemix",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "IBM Bluemix",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/providers/bluemix"
        },
        "parent": {
          "href": "http://localhost:9292/api/vendors/cloud_foundry_v2"
        },
        "endpoints": {
          "href": "http://localhost:9292/api/providers/bluemix/endpoints"
        }
      }
    }
  ],
  "_links": {
    "self": {
      "href": "http://localhost:9292/api/vendors/cloud_foundry_v2/providers"
    },
    "parent": {
      "href": "http://localhost:9292/api/vendors/cloud_foundry_v2"
    }
  }
}
```

##### Register new provider
The only requirement is that the name must be unique amongst the providers of *all* vendors:

    POST /api/vendors/cloud_foundry_v2/providers
    body: {"provider":{"name":"mynewcloudfoundryprovider"}}

#### Endpoints

Endpoints can be managed *without authentication* and support `GET`, `POST`, `PATCH`, `DELETE` requests.

##### List all endpoints that are registered for a provider
```
GET /api/providers/bluemix/endpoints
```

```json
{
  "size": 2,
  "endpoints": [
    {
      "id": "bluemix-eu-gb",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "Europe - Great Britain",
      "url": "https://api.eu-gb.bluemix.net",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/endpoints/bluemix-eu-gb"
        },
        "parent": {
          "href": "http://localhost:9292/api/providers/bluemix"
        },
        "applications": {
          "href": "http://localhost:9292/api/endpoints/bluemix-eu-gb/applications"
        }
      }
    },
    {
      "id": "bluemix-us-south",
      "created_at": "2015-02-25T08:38:30Z",
      "updated_at": "2015-02-25T08:38:30Z",
      "name": "United States - South",
      "url": "https://api.ng.bluemix.net",
      "_links": {
        "self": {
          "href": "http://localhost:9292/api/endpoints/bluemix-us-south"
        },
        "parent": {
          "href": "http://localhost:9292/api/providers/bluemix"
        },
        "applications": {
          "href": "http://localhost:9292/api/endpoints/bluemix-us-south/applications"
        }
      }
    }
  ],
  "_links": {
    "self": {
      "href": "http://localhost:9292/api/providers/bluemix/endpoints"
    },
    "parent": {
      "href": "http://localhost:9292/api/providers/bluemix"
    }
  }
}
```

##### Register new endpoint
The only requirement is that the name must be unique amongst the endpoints of *all* providers:

    POST /api/providers/cloud_foundry_v2/endpoints
    body: {"endpoint":{"name":"mynewcloudfoundryendpoint"}}

#### Application logs

TODO: move to the proper section in this README file

##### Download a selected logfile of an application

```shell
curl -X "GET" "http://localhost:9292/api/endpoints/cf-bosh-local/applications/{app_id}/logs/{log_id}/download" -H "Authorization: {auth_header}" -O -J
```

##### Download all logfiles of an application

```shell
curl -X "GET" "http://localhost:9292/api/endpoints/cf-bosh-local/applications/{app_id}/logs/download" -H "Authorization: {auth_header}" -O -J
```

##### Tail a selected logfile of an application

```shell
curl -X "GET" "http://localhost:9292/api/endpoints/cf-bosh-local/applications/{app_id}/logs/{log_id}/tail" -H "Authorization: {auth_header}"
```

### Native calls (experimental)

You can also execute native calls against the endpoint's API by using PaaSal.
This feature is included as experimental functionality and **does not returned unified objects or errors**.
The response of the API is passed 1:1 to the REST client.

The native calls can be made either against the endpoint or against an application.
Allowed HTTP methods are `GET`, `POST`,`PATCH`, `PUT` and `DELETE`.
Data embedded in a requests body is used 1:1 in the API call, header information are going to be discarded.

Please be aware that you must also include the API version in the path if required by the platform.
For instance Cloud Foundry requests would have to look like: `.../call/v2/app_usage_events`

##### Execute a native API call against the endpoint
In this example we want to get the current user's account information.
we append the `call` action to the endpoint, followed by the API's native path to the resource: `account`

```
GET /api/endpoints/heroku/call/account
```

```json
{
  "allow_tracking": true,
  "beta": false,
  "email": "theusersemail@provider.domain",
  "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
  "last_login": "2014-11-25T08:52:59Z",
  "name": " ",
  "two_factor_authentication": false,
  "verified": false,
  "created_at": "2014-11-18T09:37:21Z",
  "updated_at": "2015-02-18T18:57:33Z",
  "default_organization": null
}
```

##### Execute a native API call against an endpoint's application
In this example we try to list the builds of an Heroku application.
Therefore we append the `call` action to the application at the endpoint, followed by the API's native path to the resource: `builds`

```
GET /api/endpoints/heroku/applications/the_application_name/call/builds
```

```json
[
  {
    "created_at": "2014-11-18T10:33:25+00:00",
    "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
    "slug": {
      "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    },
    "source_blob": {
      "url": null,
      "version": null,
      "version_description": null
    },
    "status": "succeeded",
    "updated_at": "2014-11-18T10:43:34+00:00",
    "user": {
      "email": "theusersemail@provider.domain",
      "id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    }
  }
]
```

## Configuration

**TODO**

Several parts of PaaSal can be configured, e.g. whether to persist your data or always start with a clean instance.

### Vendors, Providers and Endpoints

A vendor is reflected by an adapter implementation, but the providers and their endpoints can either be changed at runtime or be configured in `.yaml` files. These adapter configuration files are located in the project directory at `config/adapters`.

###### Example adapter configuration, here: Openshift 2

```yaml
  ---
  name: "Openshift 2"
  id: "openshift_v2"
  providers:
    -
      name: "Openshift Online"
      id: "openshift-online"
      endpoints:
        -
          name: "Openshift Online"
          id: "openshift-online"
          url: "openshift.redhat.com/broker/rest"
```

### Application configuration

Some aspects, for instance where the server shall save its storage files, can be adjusted.

```ruby
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
```

#### Database backend

The database backend can be specified in the `paasal.rb` configuration file.
It defaults to [Daybreak](https://github.com/propublica/daybreak) on Unix systems
and [LMDB](https://github.com/minad/lmdb) on Windows.

## API clients

### REST client

The API can be used with the REST client of your choice.

##### Accept Header

Paasal always uses the latest API version if no `Accept` header is specified.
We therefore **strongly encourage** you to always specify the `Accept` header.
The vendor thereby must be set to `paasal` and the version must be available.
Otherwise an error with the HTTP status `406` is returned.
A sample `Accept` header would be:

```
Accept = application/vnd.paasal-v1
```

##### Error codes

The application uses the following subset of error codes:

```
400: Bad Request
401: Unauthorized
403: Forbidden
404: Resource not found
406: API vendor or version not found
422: Unprocessable Entity due to invalid parameters
500: Internal processing error
```

All errors are returned in a common schema:

```json
{
  "status": HTTP_STATUS_CODE,
  "message": SIMPLE_ERROR_MESSAGE,
  "dev_message": DEVELOPER_MESSAGE_WITH_TECHNICAL_DETAILS_TO_RESOLUTION,
  "error_code": UNIQUE_ERROR_CODE,
  "more_info": LINK_TO_DOCUMENTATION_DESCRIBING_THE_ERROR
}
```

### Language specific clients

As of now, there is no language specific API client available.
As a reward of providing swagger-compatible API docs, clients can be generated for several languages:
`Scala`, `Flash`, `Java`, `Objc`, `PHP`, `Python`, `Python3`, `Ruby`

For detailed information, please have a look at the [swagger-codegen project](https://github.com/swagger-api/swagger-codegen).

## Adapters

### Heroku

#### Issues

*No known issues*

### Cloud Foundry v2

#### Issues
**Logs**
CF stopped to provide the `stdout` and `stderr` files in the `logs` directory.
Currently we do not know of an approach to fetch recent log entries without registering an additional service on the application.

Moreover, logs can only be retrieved as long as at least once instance of the CF application is running, hence the application state is `running`.
If there are no logs that can be retrieved, the log list will be empty and the direct call of a log file will result in an 404 error.

### Openshift v2

#### Issues

*NOT YET IMPLEMENTED*

### cloudControl

#### Issues
**Application update**
An application can't be updated, the `name` and `runtimes` can't be changed once created.

**Application lifecycle**
Applications on cloudControl can't be explicitly started or stopped.
They start automatically upon the successful deployment of a valid application and stop once the _deployment_ has been deleted.

**Logs**
Log messages, for instance the request entries, do not appear instantly in the log.
It may take some seconds or even minutes for them to show up.

## Tests

The tests are divided into 3 categories, _unit_, _integration_ and _adapter_ tests.
You can either call all tests or each suite seperately.

**Invoke:**

```
bundle exec rake spec
```

### Unit Tests

**Invoke:**

```
bundle exec rake spec:suite:unit
```

### Integration Tests

**Invoke:**

```
bundle exec rake spec:suite:integration
```

### Adapter Tests

The adapter tests rely on previously recorded interactions with the provider's endpoints. They do not invoke external HTTP requests.
When code changes result in different requests, the interactions have to be re-recorded.

**Invoke:**

```
bundle exec rake spec:suite:adapters
```

##### Recording

Recording new VCR cassettes requires you to have an account at the platform that shall be recorded.
The credentials must be specified in the `config/.credentials` file.

The file is ignored and shall _never_ be committed. It must use the following syntax:

```
heroku:
  user:     'my_heroku_username'
  password: 'my_heroku_usernames_password'
```

A complete .credentials file could then look like:

```yaml
heroku:
  id:       'my_heroku_user_id'
  user:     'my_heroku_username'
  password: 'my_heroku_usernames_password'

bluemix-eu-gb:
  user:     'my_bluemix_username'
  password: 'my_bluemix_usernames_password'
  username: 'my_bluemix_username_with_encoded_umlauts'

cloudcontrol:
  user:     'my_cc_email'
  password: 'my_cc_usernames_password'
  username: 'my_cc_username'

openshift-online:
  user:     'my_os_email'
  password: 'my_os_usernames_password'
  id:       'my_os_user_id'
```

To record the interactions, you only have to call the Rake `record` task, eg. by calling:

```
bundle exec rake record`
```

**Notes:**
* You must be allowed to create at least 3 additional applications with your account, otherwise the quota restrictions will invalidate the test results.
* A complete recording of a single vendor can currently take up to 10 minutes.
If you only require certain functionality to be tested, make sure to comment out irrelevant sections in the `spec/adapter/support/shared_example_adapters_valid.rb` file.
* cloudControl requires you to change the application names if the previous recording was made within the last 2 days, otherwise if fails because the name is still locked.
Change the name in the `spec/adapter/v1/cloud_control_spec.rb`.

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

Until the first release (v1), the initial version is: `0.1.0`.

## Project structure

```
app # The PaaSal application
app/adapters # The adapter implementations to communicate with the vendor's platforms, grouped by API version.
app/api # Everything that is directly related to the RESTfulGrape API: entities, embedded helpers and the actual API version's definitions
app/core # All other functionality used throughout the application, but rather unrelated to the Grape API: http requests, authentication, errors, etc.
app/middleware # Rack middleware layers for authentication, request ids and logging
app/models # The object classes that are to be maintained in the database: Vendor, Provider, Endpoint, ...
bin # Binary startup files
config # Configuration files for PaaSal and its adapters
lib # Monkey patched classed, extensions and the gem definition files
public # public directory for rack, hosts the swagger-ui files for the live API documentation
schemas # Kwalify schemas, used to parse the configuration and load new vendors at startup
scripts # Initialization scripts, bootstrapping rackup and shutdown hooks to cleanup the database
spec # All rspec test suites
```

## Contributing

Everyone is welcome to contribute via

- Forks & Pull Requests
- Issues
- Emails
- Anything that comes into your mind ;-)

Please make sure that all contributions pass the `bundle exec rake` command,
which tests for code style violations and executes all tests.

## Further documentation

[Add a vendor (or implement a new adapter)](wiki/implement_new_adapter.md)

## shield.io badges (not working)

[![Build Status](https://img.shields.io/travis/croeck/paasal.svg?style=flat-square&token=4rnK13d2FLuvMVhBBFCH)](https://magnum.travis-ci.com/croeck/paasal)
[![Gem Version](http://img.shields.io/gem/v/paasal.svg?style=flat-square)](http://badge.fury.io/rb/paasal)
[![Dependency Status](https://img.shields.io/gemnasium/croeck/paasal.svg?style=flat-square)](https://gemnasium.com/croeck/paasal)
[![Code Climate](https://img.shields.io/codeclimate/github/croeck/paasal.svg?style=flat-square)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
[![Test Coverage](https://img.shields.io/codeclimate/coverage/github/croeck/paasal.svg?style=flat-square)](https://codeclimate.com/repos/54af9232695680520400157d/feed)
