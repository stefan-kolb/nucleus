![PaaSal](icons/paasal_200w.png "Platform as a Service abstraction layer")

[![Build Status](https://magnum.travis-ci.com/stefan-kolb/paasal.svg?token=VEm1aJ8ydBNAfhASH8xN&branch=master)](https://magnum.travis-ci.com/stefan-kolb/paasal)
[![Dependency Status](https://gemnasium.com/4ae6979b87f7b5dc47956b2842e1166b.svg)](https://gemnasium.com/stefan-kolb/paasal)
[![Code Climate](https://codeclimate.com/repos/55dd8cda695680629e01442a/badges/f5259f91f03175f6ee36/gpa.svg)](https://codeclimate.com/repos/55dd8cda695680629e01442a/feed)
[![Test Coverage](https://codeclimate.com/repos/55dd8cda695680629e01442a/badges/f5259f91f03175f6ee36/coverage.svg)](https://codeclimate.com/repos/55dd8cda695680629e01442a/coverage)

_PaaSal_ is a RESTful abstraction layer to achieve unified deployment and management functions for Platform-as-a-Service (PaaS) providers.  
The API is build using [Ruby](https://www.ruby-lang.org) and the [grape framework](https://github.com/intridea/grape).
It provides fully compliant [swagger](http://swagger.io/) schemas that serve for documentation and client generation.

PaaSal differentiates between Vendors, Providers and Endpoints.
A *Vendor* is the organziation that developed the platform software.
A *Provider* runs the platform, which always has at least one *Endpoint*, but can also have multiple endpoints for different regions.

## Table of Contents

* [Supported Vendors](#supported-vendors)
* [Usage](#usage)
  * [Ruby Interpreter Compatibility](#ruby-interpreter-compatibility)
  * [Installation instructions](#installation-instructions)
  * [Use in your application](#use-in-your-application)
  * [Use the API](#use-the-api)
    * [Start the server](#start-the-server)
    * [API endpoints](#api-endpoints)
* [Functionality](#functionality)
  * [Authentication](#authentication)
    * [Special characters (umlauts, ....)](#special-characters-umlauts-)
  * [Core constructs](#core-constructs)
    * [Vendors](#vendors)
    * [Providers and Endpoints](#providers-and-endpoints)
  * [Custom API calls (experimental)](#custom-api-calls-experimental)
    * [Execute a custom API call against the endpoint](#execute-a-native-api-call-against-the-endpoint)
    * [Execute a custom API call against an endpoint's application](#execute-a-native-api-call-against-an-endpoints-application)
* [Adapters](#adapters)
  * [Heroku](#heroku)
  * [Cloud Foundry v2](#cloud-foundry-v2)
  * [Openshift v2](#openshift-v2)
  * [cloudControl](#cloudcontrol)
* [Configuration](#configuration)
  * [Vendors, Providers and Endpoints](#vendors-providers-and-endpoints)
  * [Application configuration](#application-configuration)
* [API client(s)](#api-clients)
  * [Accept Header](#accept-header)
  * [Error codes](#error-codes)
  * [Language specific clients](#language-specific-clients)
* [Tests](#tests)
* [Schema validation](#schema-validation)
* [Versioning](#versioning)
* [Security](#security)
* [Project structure](#project-structure)
* [Contributing](#contributing)
* [Further documentation](#further-documentation)

## Supported Vendors

- [Heroku][heroku]
- [Cloud Foundry][cloud_foundry] (v2)
  - [AppFog][appfog], [Anynines][anynines], [IBM Bluemix][bluemix], [Pivotal Web Services][pivotal_ws], [HP Helion][hp_helion]
- [Openshift][openshift_v2] (v2)
  - [OpenShift Online][openshift_online], [getup Cloud][getup]
- [cloudControl][cloudcontrol]
  - [dotCloud][dotcloud], [Cloud&Heat App Elevator][cloud&heat], [exoscale Apps][exoscale]

[heroku]: https://www.heroku.com

[cloud_foundry]: https://www.cloudfoundry.org/
[appfog]: https://www.ctl.io/appfog/
[anynines]: http://www.anynines.com/
[bluemix]: https://console.ng.bluemix.net/
[pivotal_ws]: https://run.pivotal.io/
[hp_helion]: http://www8.hp.com/de/de/cloud/helion-devplatform-overview.html

[openshift_v2]: https://www.openshift.com/
[openshift_online]: https://www.openshift.com/features/index.html
[getup]: https://getupcloud.com/index_en.html

[cloudcontrol]: https://www.cloudcontrol.com
[dotcloud]: https://www.dotcloud.com/
[cloud&heat]: https://www.cloudandheat.com/de/paas.html
[exoscale]: https://www.exoscale.ch/add-on/apps/

More information on the vendors and the associated adapter can be found in the [adapters section](#adapters).

## Usage

PaaSal can either be used as standalone application/service, or as part of another ruby application.
Please make sure to obey the following installation instructions before starting to use PaaSal.

### Ruby Interpreter Compatibility

PaaSal is supposed to run on Ruby >= 2.0.
**It currently won't work on JRuby.**

### Installation instructions

1) The following (executable) files must be available on the system's *PATH*:

- git
- ssh

#### Platform-specific notes

Unix systems should run fine out of the box, whereas Windows systems might need some adjustments:

##### Windows

Both files should be located in the `Git/bin` installation directory of [msysGit](https://msysgit.github.io/).
PaaSal is verified to work with [msysGit](https://msysgit.github.io/) and the included version of `OpenSSH`.
We did not verify other alternatives, e.g. PuTTY's `plink.exe`.
PuTTY is supposed to (maybe anyone knows how to fix this?) not work due to the lack of the `-o UserKnownHostsFile=NUL -o StrictHostKeyChecking=no` options that allow to connect any git repository without confirmation of the host's identity.

###### Troubleshooting

**Eventmachine**:

Eventmachine sometimes fails with the error `Encryption not available on this event-machine`.
A fix is available, but requires a few steps:

1) Uninstall the gem

```shell
$ gem uninstall eventmachine
```

2) Download the OpenSSL package from [http://packages.openknapsack.org/openssl/openssl-1.0.0k-x86-windows.tar.lzma](http://packages.openknapsack.org/openssl/openssl-1.0.0k-x86-windows.tar.lzma)
Do NOT use the latest version!

3) Extract it to the desired location

4) Re-install the gem and point to the OpenSSL installation directory. Escape backslashes or use forward slashed.

```shell
$ gem install eventmachine -- --with-ssl-dir=C:/SSL
```

### Use in your application

#### Require paasal and mark as dependency

Add a dependency on the PaaSal gem, for instance in your application's Gemfile,

```ruby
gem 'paasal'
```

upon which you would update your bundle.

```shell
$ bundle install
```

Of course you could also install the gem yourself as:

```shell
$ gem install paasal
```

Finally require the gem in your application

```ruby
require 'paasal'
```

#### Communicate with an endpoint

1) Configuration [optional]

Adapt the configuration to your needs and adjust the values via `paasal_config`.
The configuration *must* be changed before initializing the `AdapterResolver`, otherwise the configuration is locked and can't be changed anymore.

For more information have a look at the [configuration](#configuration) section.

2) Show all currently available API versions:

```ruby
Paasal::VersionDetector.api_versions
```

3) Instantiate the AdapterResolver for the desired API version:

```ruby
resolver = Paasal::AdapterResolver.new('v1')
```

4) Show all adapters that are supported by PaaSal on this specific API version:

```ruby
resolver.adapters
```

```ruby
{"cloudcontrol"=>Paasal::Adapters::V1::CloudControl, "cloud_foundry_v2"=>Paasal::Adapters::V1::CloudFoundryV2, "heroku"=>Paasal::Adapters::V1::Heroku, "openshift_v2"=>Paasal::Adapters::V1::OpenshiftV2}
```

5) Create the adapter that you with to use, here we load the cloudControl adapter:

```ruby
adapter = resolver.load('cloudcontrol', 'api.cloudcontrol.com', 'your_username', 'your_password')
```

By default, the adapter will be populated with the default configuration options that are defined in the vendor's configuration for the selected endpoint_url.
If you are using a custom installation, e.g. of *Openshift* or *Cloud Foundry*, make sure to pass the option that describe the `app_domain`.
Otherwise the `web_url` links created by PaaSal will be malformed.

```ruby
adapter = resolver.load('cloud_foundry_v2', 'api.example.org', 'your_username', 'your_password', app_domain: 'apps.example.org', check_ssl: false)
```

6) Start using the platform and invoke commands:

```ruby
# Show available regions
adapter.regions
# Create our first application
app = adapter.create_application(region: 'default', name: 'myusersfirstapplication', runtimes: ['nodejs'])
# And delete the application again ;-)
adapter.delete_application(app[:id])
```

Check the **documentation** of the `Paasal::Adapters::V1::Stub` adapter (or any other API version) for a complete list of the supported actions.
You can also refer to the documentation of the REST interface to get detailed information about the parameter options of `post` and `put` commands,
including which fields are required and those that are only optional.

### Use the API

Besides including the abstraction layer in your application, PaaSal can also be started and serve the RESTful API:
For detailed usage information go to the section [API client(s)](#api-clients).

#### Start the server

A rack server can be started in multiple ways.
The most convenient solution is to use the provided script:  

```shell
$ ./bin/paasal
```

However, you can also start the API using the [thin](http://code.macournoyer.com/thin/) server:

```shell
$ rackup -s thin config.ru
```

Due to limitations in the log tailing process, currently PaaSal requires `thin` and does not work on other Rack servers.
In theory, it should be possible to make other Rack servers work that also utilize [eventmachine](https://github.com/eventmachine/eventmachine).

#### HTTPS

We highly encourage you to **only use https connections** when your application is running in production or used outside of your local computer.
This is due to the fact that all passwords are passed via the HTTP basic authentication, which does not encrypt your data so that any third party could log and identify your credentials.

To enforce this policy, PaaSal will automatically redirect all connections on plain HTTP to HTTPS connections if it is running in production (detected via *RACK_ENV*).

#### API endpoints

The API of PaaSal is documented by the use of [swagger](http://swagger.io).
After your started a server instance, you can access an interactive [swagger-ui](https://github.com/swagger-api/swagger-ui) at the `/docs` path.

## Functionality

The following list shows the degree to which the adapters implement the offered methods.
This list is auto-generated and can be shown via:

```
$ bundle exec rake evaluation:compatibility:markdown
```

**State: 10/14/2015**

Method / Vendor|cloudControl|Cloud Foundry v2|Heroku|Openshift v2
:--|:-:|:-:|:-:|:-:
auth_client|&#10003;|&#10003;|&#10003;|&#10003;
regions|&#10003;|&#10003;|&#10003;|&#10003;
region|&#10003;|&#10003;|&#10003;|&#10003;
applications|&#10003;|&#10003;|&#10003;|&#10003;
application|&#10003;|&#10003;|&#10003;|&#10003;
create_application|&#10003;|&#10003;|&#10003;|&#10003;
update_application|&#10007;|&#10003;|&#10003;|&#10007;
delete_application|&#10003;|&#10003;|&#10003;|&#10003;
domains|&#10003;|&#10003;|&#10003;|&#10003;
domain|&#10003;|&#10003;|&#10003;|&#10003;
create_domain|&#10003;|&#10003;|&#10003;|&#10003;
delete_domain|&#10003;|&#10003;|&#10003;|&#10003;
env_vars|&#10003;|&#10003;|&#10003;|&#10003;
env_var|&#10003;|&#10003;|&#10003;|&#10003;
create_env_var|&#10003;|&#10003;|&#10003;|&#10003;
update_env_var|&#10003;|&#10003;|&#10003;|&#10003;
delete_env_var|&#10003;|&#10003;|&#10003;|&#10003;
start|&#10003;|&#10003;|&#10003;|&#10003;
stop|&#10007;|&#10003;|&#10003;|&#10003;
restart|&#10007;|&#10003;|&#10003;|&#10003;
deploy|&#10003;|&#10003;|&#10003;|&#10003;
rebuild|&#10003;|&#10003;|&#10003;|&#10003;
download|&#10003;|&#10003;|&#10003;|&#10003;
scale|&#10003;|&#10003;|&#10003;|&#10003;
log?|&#10003;|&#10003;|&#10003;|&#10003;
logs|&#10003;|&#10003;|&#10003;|&#10003;
log_entries|&#10003;|&#10003;|&#10003;|&#10003;
tail|&#10003;|&#10003;|&#10003;|&#10007;
services|&#10003;|&#10003;|&#10003;|&#10003;
service|&#10003;|&#10003;|&#10003;|&#10003;
service_plans|&#10003;|&#10003;|&#10003;|&#10003;
service_plan|&#10003;|&#10003;|&#10003;|&#10003;
installed_services|&#10003;|&#10003;|&#10003;|&#10003;
installed_service|&#10003;|&#10003;|&#10003;|&#10003;
add_service|&#10003;|&#10003;|&#10003;|&#10003;
change_service|&#10003;|&#10003;|&#10003;|&#10007;
remove_service|&#10003;|&#10003;|&#10003;|&#10003;

### Core constructs

PaaSal could support any constellation of PaaS offers that are currently available.
In order to do so, we differentiate between 3 types:

The **vendor**, or the PaaS platform, which determines the functionality,
a **provider** that runs the vendor's platform and offers it to its customers and finally
the **endpoint** of the provider's offer.

For most scenarios the *endpoint* is identical to the *provider*, but in some cases,
for instance on [IBM Bluemix](https://console.ng.bluemix.net), *endpoints* distinguish different deployment regions.

If running PaaSal as webservice, all changes made to these entities at runtime will be discarded,
unless you enable the functionality in the configuration and specify a location where to persist the data to.

#### Vendors

You can use the API of PaaSal to show a list of all currently supported vendors.
This request if publicly available and does not require any authentication.

However, you can't create, delete or update a vendor at runtime because they represent the logic to communicate with their platform.
All developers that want to have more information on how to add a new vendor can take a look at the instructions: [Add a vendor (or implement a new adapter)](wiki/implement_new_adapter.md)

#### Providers and Endpoints

Providers and Endpoints can be managed *without authentication* and support `GET`, `POST`, `PATCH`, `DELETE` requests.

A new entity can be registered at runtime by sending a `POST` request.
Whereas the Provider only requires a `name`, the endpoint also needs a further attribute, the `url`.
Please refer to the swagger-ui documentation for additional information about the requests.

### Authentication

Authentication against the endpoint is managed by PaaSal.
The credentials must be provided as [Basic authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) header **within each single request**.

```
Authorization: Basic thebase64encodedcredentialsstring
```

#### Special characters (umlauts, ....)

The usage of special characters, for instance the german umlauts as ä, ö and ü may cause issues with some platforms.
Please make sure to select the correct encoding for your credentials before encoding them with base64:

* Stackato 3.4.2
  * Different encodings cause the requests to crash and return status 500

### Application logs

Below are some examples how to use the API in order to obtain detailed application logs.

#### Download a selected logfile of an application

```shell
curl -X "GET" "http://localhost:9292/api/endpoints/cf-bosh-local/applications/{app_id}/logs/{log_id}/download" -H "Authorization: {auth_header}" -O -J
```

#### Download all logfiles of an application

```shell
curl -X "GET" "http://localhost:9292/api/endpoints/cf-bosh-local/applications/{app_id}/logs/download" -H "Authorization: {auth_header}" -O -J
```

#### Tail a selected logfile of an application

```shell
curl -X "GET" "http://localhost:9292/api/endpoints/cf-bosh-local/applications/{app_id}/logs/{log_id}/tail" -H "Authorization: {auth_header}" --raw -v
```

### Custom API calls (experimental)

You can also execute custom API calls against the endpoint's API by using PaaSal.
This feature is included as experimental functionality and **does not return unified objects or errors**.
The response of the API is passed 1:1 to the REST client.

The custom calls can be made either against the endpoint or against an application.
Allowed HTTP methods are `GET`, `POST`,`PATCH`, `PUT` and `DELETE`.
Data embedded in a requests body is used 1:1 in the API call, header information are going to be discarded.

Please be aware that you must also include the API version in the path if required by the platform.
For instance Cloud Foundry requests would have to look like: `.../call/v2/app_usage_events`

##### Execute a custom API call against the endpoint

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

##### Execute a custom API call against an endpoint's application

In this example we try to list the builds of an Heroku application.
Therefore we append the `call` action to the application at the endpoint, followed by the API's native path to the resource: `builds`

```
GET /api/endpoints/heroku/applications/the_application_name/call/builds
```

The response is the unprocessed response of the Heroku API as shown in the previous example.

## Adapters

The functionality to communicate with different platforms is implemented in so called *adapters*.
However, not each adapter can fully support the abstract PaaSal definitions.
Please refer to the [functionality section](#functionality) for more information about the supported features.

### Heroku

Providers: [Heroku](http://heroku.com)

*No known issues*

### Cloud Foundry v2

Providers: [AppFog][appfog], [Anynines][anynines], [IBM Bluemix][bluemix], [Pivotal Web Services][pivotal_ws], [HP Helion][hp_helion]

#### Issues

**Logs**

CF stopped to provide the `stdout` and `stderr` files in the `logs` directory.
Currently we do not know of an approach to fetch recent log entries without registering an additional service on the application.

Moreover, logs can only be retrieved as long as at least once instance of the CF application is running, hence the application state is `running`.
If there are no logs that can be retrieved, the log list will be empty and the direct call of a log file will result in an 404 error.

**Services**

- As of now we focus only allow bindable services and create a new instance of the service to add
- Therefrore services must be `active` and `bindable`
- Only one instance of the same service can be bound to the application

### Openshift v2

Providers: [OpenShift Online][openshift_online], [getup Cloud][getup]

#### Issues

**Application update**

An application can't be updated, the `name` and `runtimes` can't be changed once created.

**Application scaling**

Applications not created with PaaSal can't be scaled if they were created with the attribute `scalable = false`

**Services**

- Services can be added to the application, but scaling (gears, memory allocation, ...) and
further configuration are not supported as of now.
- We focus on the `embedded` cartridges and leave out the `standalone` services such as *Jenkins*.
- With no service plans and therefore nothing to change, the *change service* function is not implemented.

**Performance**

Recording is really slow. Even worse, actions quite often fail with Openshift internal timeouts.

### cloudControl

Providers: [cloudControl][cloudcontrol], [dotCloud][dotcloud], [Cloud&Heat App Elevator][cloud&heat], [exoscale Apps][exoscale]

#### Issues

**Application update**

An application can't be updated, the `name` and `runtimes` can't be changed once created.

**Application lifecycle**

Applications on cloudControl can't be explicitly stopped or restarted.
They start after the successful build of the application, which is therefore postponed up to the first invocation of the start operation.
Application only stop once the corresponding _deployment_ has been deleted.

**Logs**

Log messages, for instance the request entries, do not appear instantly in the log.
It may take some seconds or even minutes for them to show up.

## Configuration

Several parts of PaaSal can be configured, e.g. whether to persist your data or always start with a clean instance.
There are two different locations at which the configuration files can be placed.
They are described with increasing importance, meaning that the last option overwrites keys that were also configured in the previous files:

1. A file in user account's home directory. On UNIX systems this file must be placed at `~/.paasal/paasal_config.rb`, whereas it is expected at `~/paasal/paasal_config.rb` if running Windows.
2. The `config/paasal_config.rb` file in the project's directory

#### Database backend

The database backend can be specified in the `config/paasal_config.rb` configuration file.
It defaults to [Daybreak](https://github.com/propublica/daybreak) on Unix systems
and [LMDB](https://github.com/minad/lmdb) on Windows.

Note: *[Daybreak](https://github.com/propublica/daybreak) does not run on Windows*

### Vendors, Providers and Endpoints

A vendor is reflected by an adapter implementation, but the providers and their endpoints can either be changed at runtime or via `.yaml` configuration files.
These adapter configuration files are located in the project directory at `config/adapters`.

#### Add a new Provider

To add a new provider, open the `config/adapters` directory and select the platform that the provider is using.
For more explanations of the fields, or if the platform is not listed, please refer to the Guide [how to implement a new adapter)](wiki/implement_new_adapter.md).

Next, add your provider and its endpoint(s) to the configuration file.

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

## API clients

The API can be used with the REST client of your choice.

### Accept Header

Paasal always uses the latest API version if no `Accept` header is specified.
We therefore **strongly encourage** you to always specify the `Accept` header.
The vendor thereby must be set to `paasal` and the version must be available.
Otherwise an error with the HTTP status `406` is returned.
A sample `Accept` header would be:

```
Accept = application/vnd.paasal-v1
```

### Error codes

The application uses the following subset of error codes:

```
400: Bad Request
401: Unauthorized
404: Resource not found
406: API vendor or version not found
422: Unprocessable Entity due to invalid parameters
500: Internal processing error
501: Not implemented, adapter does not provide this feature
503: Destination service temporarily unavailable
504: Gateway Time-out
```

All errors are returned in a common schema:

```ruby
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
As a reward of providing swagger-compatible API docs, clients can be generated for several languages.
For detailed information, please have a look at the [swagger-codegen project](https://github.com/swagger-api/swagger-codegen).

## Tests

The tests are divided into 3 categories, _unit_, _integration_ and _adapter_ tests.
You can either call all tests or each suite separately.

```
bundle exec rake spec
bundle exec rake spec:suite:unit
bundle exec rake spec:suite:integration
bundle exec rake spec:suite:adapters
```

## Schema validation

The generated schema can be validated against the [swagger specification](https://github.com/swagger-api/swagger-spec).
Please have a look at the [swagger-codegen project](https://github.com/swagger-api/swagger-codegen).

## Versioning

PaaSal follows the [Semantic Versioning](http://semver.org/) standard.
Therefore, PaaSal also allows to serve multiple versions of the API and provide legacy support.

However, be aware that
__each non-backward compatible change of the application must result in an increase of the major version.__

Until the first release (v1), the initial version is: `0.1.0`.

## Security

As described in the [HTTPS](#https) section, we strongly encourage you to only run PaaSal with HTTPS.

### Public key registration

PaaSal uses the SSH key authentication for Git deployments.
The private (!) key that will be used is located at `config/paasal_git_key.pem`.
Using the pre-generated key mitigates issues with the key usage / generation on various platforms.
To prevent abuse we register the key before each command and immediately remove the key once the command has been executed.

**To improve the security of your deployment, you can use your own custom private key.
To do so, set the `paasal_config.ssh.custom_key` option in the [common configuration](config/paasal_config.rb) to the location of the private key file.**

## Project structure

```
bin # Binary startup files and GIT__SSH env. agents
config # Configuration files for PaaSal and its adapters
doc # Generated YARD documentation
lib # The PaaSal application source code
lib/paasal # Gem compatible directory of the core, includes the AdapterResolver class
lib/paasal/adapters # The adapter implementations to communicate with the vendor's platforms, grouped by API version.
lib/paasal/core # All other functionality used throughout the application, but rather unrelated to the Grape API: http requests, authentication, errors, etc.
lib/paasal/ext # Monkey patched classed and extensions
lib/paasal/scripts # Initialization scripts, bootstrapping and shutdown hooks
lib/paasal_api/api # Everything that is directly related to the RESTful Grape API: entities, embedded helpers and the actual API version's definitions
lib/paasal_api/ext # Monkey patched classed and extensions related only to the API
lib/paasal_api/import # Import management of the adapter configuration files
lib/paasal_api/persistence # The persistence layer, including the DAOs and the entity's models (Vendor, Provider, Endpoint, ...)
lib/paasal_api/rack_middleware # Rack middleware layers for authentication, request ids and logging
lib/paasal_api/scripts # Initialization scripts, bootstrapping, rackup and shutdown hooks of the API
public # public directory for rack, hosts the swagger-ui files for the live API documentation
schemas # Kwalify schemas, used to parse the configuration and load new vendors at startup
spec # All rspec test suites
tasks # Rake tasks, mostly related to generate tables and statistics
wiki # Further documentation files
```

## Contributing

We love contributions from everyone! See our [contribution guidelines](CONTRIBUTING.md) for details.

## Further documentation

- [Add a vendor (or implement a new adapter)](wiki/implement_new_adapter.md)
- [Adapter Tests](wiki/adapter_tests.md)
