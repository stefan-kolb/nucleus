module Paasal
  module API
    module V1
      class Regions < Grape::API
        helpers SharedParamsHelper

        resource 'endpoints/:endpoint_id/regions' do
          desc 'Get all deployment regions that can be used with this endpoint' do
            success Models::Regions
            failure ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
          end
          get '/' do
            regions = with_authentication { adapter.regions }
            present regions, with: Models::Regions
          end

          desc 'Get a specific deployment region' do
            success Models::Region
            failure [[200, 'Region retrieved', Models::Region]].concat ErrorResponses.standard_responses
          end
          params do
            use :endpoint_id
            requires :region_id, type: String, desc: 'The regions ID'
          end
          get ':region_id' do
            region = with_authentication { adapter.region params[:region_id] }
            present region, with: Models::Region
          end
        end
      end
    end
  end
end
