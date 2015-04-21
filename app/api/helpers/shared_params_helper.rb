# noinspection ALL
module Paasal
  module SharedParamsHelper
    extend Grape::API::Helpers

    params :endpoint_id do
      requires :endpoint_id, type: String, desc: "The endpoint's ID"
    end

    params :application_context do
      use :endpoint_id
      requires :application_id, type: String, desc: "The application's ID"
    end

    params :env_var_id do
      requires :env_var_id, type: String, desc: "The environment variable's ID"
    end

    params :domain_id do
      requires :domain_id, type: String, desc: "The domain's ID"
    end

    params :log_id do
      requires :log_id, type: String, desc: 'The ID of the logfile'
    end

    params :service_id do
      requires :service_id, type: String, desc: 'The ID of the service'
    end

    params :service_plan_id do
      requires :service_plan_id, type: String, desc: 'The ID of the service plan'
    end
  end
end
