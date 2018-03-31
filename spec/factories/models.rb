require 'active_support/core_ext'

FactoryBot.define do
  sequence :uuid do |_|
    SecureRandom.uuid
  end

  factory :adapter, class: Nucleus::AdapterIndexEntry do
    url { Faker::Internet.url }
    id nil
    adapter_clazz nil
  end

  factory :endpoint, class: Nucleus::Endpoint do
    id { generate(:uuid) }
    name { Faker::Internet.slug }
    url { Faker::Internet.url }
    created_at { Faker::Date.between(180.days.ago, 90.days.ago).iso8601 }
    updated_at { Faker::Date.between(90.days.ago, Date.today).iso8601 }
    provider nil

    after(:create) do |endpoint|
      # associate with provider
      unless endpoint.provider.nil?
        # TODO: find a solution how to test when multiple API versions are to be supported
        dao = Nucleus::API::DB::ProviderDao.instance('v1')
        provider = dao.get endpoint.provider
        provider.endpoints = [] if provider.endpoints.nil?
        provider.endpoints << endpoint.id
        # save updated association
        dao.set provider
      end
    end
  end

  factory :provider, class: Nucleus::Provider do
    id { generate(:uuid) }
    name { Faker::App.name }
    created_at { Faker::Date.between(180.days.ago, 90.days.ago).iso8601 }
    updated_at { Faker::Date.between(90.days.ago, Date.today).iso8601 }
    vendor nil

    after(:create) do |provider|
      # associate with vendor
      unless provider.vendor.nil?
        # TODO: find a solution how to test when multiple API versions are to be supported
        dao = Nucleus::API::DB::VendorDao.instance('v1')
        vendor = dao.get provider.vendor
        vendor.providers = [] if vendor.providers.nil?
        vendor.providers << provider.id
        # save updated association
        dao.set vendor
      end
    end
  end

  factory :vendor, class: Nucleus::Vendor do
    id { generate(:uuid) }
    name { Faker::App.name }
    created_at { Faker::Date.between(180.days.ago, 90.days.ago).iso8601 }
    updated_at { Faker::Date.between(90.days.ago, Date.today).iso8601 }
  end
end
