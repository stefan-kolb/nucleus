# Adapter Tests

* [Recording](#recording)
  * [Missing or invalid VCR recording](#missing-or-invalid-vcr-recording)
  * [Sensitive data](#sensitive-data)

The adapter tests rely on previously recorded interactions with the provider's endpoints.
They do not invoke external HTTP requests.
When code changes result in different requests, the interactions have to be re-recorded.

```
bundle exec rake spec:suite:adapters
```

Each interaction of the adapter tests shall be made only once.
If there are further tests that all rely on the same request, the described spec shall be marked with `:as_cassette`.
All subsequent tests in this group now use the initial recording.

```ruby
describe 'application services list empty', :as_cassette, cassette_group: 'application-services;list' do
  before { get "/endpoints/#{@endpoint}/applications/#{@app_all[:updated_name]}/services", request_headers }
  include_examples 'a valid GET request'
  include_examples 'installed service list schema'
  it 'does not contain any services' do
    expect(json_body[:services]).to eql([])
  end
end
```

The `cassette_group: 'application-services;list'` marker in this example forces the `VCR` cassettes to be placed into a
directory structure of `application-services/list/{testname}.rec`.
With this structure we can automatically evaluate request differences for a specific operation.

## Recording

Recording new VCR cassettes requires a valid user account at the platform that shall be recorded.
The `endpoint-id` that will be used during the recording is hard-coded as `@endpoint` variable inside the main adapter test file, e.g. `spec/adapter/v1/heroku/heroku_spec.rb`.
The credentials must be specified in the `config/.credentials` file.

The file is ignored by git and must _never_ be committed. It must use the following syntax:

```
endpoint-id:
  user:     'my_username'
  password: 'my_usernames_password'
```

Additional attributes can be used to filter out personal data from the recordings that may be included in the HTTP interactions (see [Sensitive data](#sensitive-data)).
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

To record the interactions, you only have to call the Rake `record` task:

```
bundle exec rake record
```

To only record interactions for a specific adapter, simply append the adapter name to the record namespace:

```
bundle exec rake record:heroku
```

**Notes:**
* You must be allowed to create at least 3 additional applications with your account, otherwise the quota restrictions will invalidate the test results.
* A complete recording of a single vendor usually takes 5 up to 15 minutes. Openshift currently takes more than 30 minutes.
If you only require a certain functionality to be tested (during development), make sure to comment out irrelevant sections in the `spec/adapter/support/shared_example_adapters_valid.rb` file.
* cloudControl requires you to change the application names if the previous recording was made within the last 2 days, otherwise if fails because the name is still locked.
Change the name in the `spec/adapter/v1/cloud_control_spec.rb`.

### Missing or invalid VCR recording

If the recorded cassette is invalid due to a recent change, tests that use this cassette are going to fail.

### Sensitive data

Most of the requests contain sensitive data that we do not want to be included in the recorded cassettes.
By implementation, the API tokens and **all** data that is specified in the `config/.credentials` file are filtered.
