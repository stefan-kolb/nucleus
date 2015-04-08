# How to implement a new adapter

In total, the process can be grouped into X steps.
To prevent errors, they should be executed in the following order:

* [Add the vendor to the configuration](#add-the-vendor-to-the-configuration)
* [Create the adapter implementation files](#create-the-adapter-implementation-files)
* [Implementation](#implementation)

## Add the vendor to the configuration

Open the directory `config/adapters` and create a new `.yml` configuration file for your platform:

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

The first level entry describes the vendor (here: Openshift 2).
**name:** The actual name of the vendor or his platform. Serves as description.
**id:** The ID under which the vendor will be available for use in the API. Should be URI compatible!
Different platform versions shall be distinguished by appending `_v{version}` to the *ID*.

The second level are the providers that shall be known to serve a PaaS running the vendors platform.
**name:** The actual name of the provider, which often equals to the vendor. Serves as description.
**id:** The ID under which the provider will be available for use in the API. Should be URI compatible!

The third level describes all API endpoints.
**name:** The actual name of the endpoint, which often equals to the provider. Serves as description.
**id:** The ID under which the endpoint will be available for use in the API. Should be URI compatible!

**NOTE:** Providers and Endpoints are optional as they could be added during runtime.

## Create the adapter implementation files

Start by selecting the API version you want to implement the adapter for.
Next, create a copy of the `app/adapters/{API_VERSION}/stub_adapter.rb` matching the API version.
The pasted file must (!) be copied to `app/adapters/{API_VERSION}/{vendor_id}/vendor_id.rb`.
Please make sure that the `{vendor_id}` actually is equal to the **ID** that was assigned to the vendor in the `.yml` configuration file.

Open the new adapter file and change the namespace so that it matches the chosen naming and inherits from the `Stub`.

```ruby
module Paasal
  module Adapters
    module {API_VERSION}
      class {VENDOR_ID} < Stub
```

Now the adapter should already be available in the API, but all calls would fail and return `501 Not implemented`.

## Tests

To include your adapter in the automatic adapter tests, we must create:

```
spec/adapter/v1/{VENDOR_ID}/{VENDOR_ID}_spec.rb
```

In this test file, you can use this basic template:

```ruby
require 'spec/adapter/adapter_spec_helper'

describe Paasal::Adapters::{API_VERSION}::{VENDOR_CLASS} do
  before :all do
    # skip these example groups / tests for this adapter. E.g.:
    # @unsupported = ['with valid credentials is compliant and application update']
    @unsupported = []
    @endpoint = '{ENDPOINT_ID}'
    @api_version = '{API_VERSION}'
    @app_min = { original_name: 'paasaltestappminproperties',
                         updated_name: 'paasaltestappminproperties',
                         region: 'default' }
    @app_all = { original_name: 'paasaltestappallupdated',
                         updated_name: 'paasaltestappallupdated',
                         region: 'default' }
  end
  before do |example|
    if skip_example?(described_class, example.metadata[:full_description], @unsupported)
      skip('This feature is currently not supported by CloudControl - 501')
    end
    # reload adapter for each test
    @adapter = load_adapter(@endpoint, @api_version)
  end

  context 'with invalid credentials' do
    let!(:request_headers) { credentials(@endpoint, false) }
    include_examples 'compliant adapter with invalid credentials'
  end

  describe 'with missing credentials' do
    let!(:request_headers) { {} }
    include_examples 'compliant adapter with invalid credentials'
  end

  context 'with valid credentials' do
    let!(:request_headers) { credentials(@endpoint) }
    include_examples 'compliant adapter with valid credentials'

    describe 'native adapter call' do
      describe 'against endpoint' do
        describe 'does fetch all available addons' do
          before do
            get "/endpoints/#{@endpoint}/call/addon", request_headers
          end
          include_examples 'a valid GET request'
          it 'with the specified structure' do
            # assumes there is at least one addon
            expect(json_body[0].keys).to include(:name, :stage, :options)
          end
          it 'with the matching content declaration' do
            expect_json_types(:array)
          end
        end
      end
    end
  end
end
```

## Implementation

Now we can start with the actual implementation. But how do you know what the adapter shall invoke and return?

The expected behaviour of the adapter methods was described in the copied `stub_adapter.rb` and should therefore be in your adapter, too.
Within the adapter tests most of the behaviour will also be tested so that you receive feedback and get to known which parts are still not properly implemented.

### Structure

In the already implemented adapters, we did split the logic into multiple modules.
With this approach, we could separate different parts of the application that are not actually related and also comply with the style guidelines that are monitored by Rubocop.

### Authentication

PaaSal already offers quite some authentication approaches that could fit your needs.
You can find the authentication clients at `app/core/auth`.

### What if the platform does not support action X?

Well, it depends ;-)

For most problems, there always is a workaround that involves some effort implement.
If the action should actually not be supported on the platform, for instance as *cloud Control* does not support to *start* or *stop* applications,
the method shall not be present in your adapter so that the `Stub` can provide a common error response.
