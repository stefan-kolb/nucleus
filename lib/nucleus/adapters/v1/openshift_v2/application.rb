module Nucleus
  module Adapters
    module V1
      class OpenshiftV2 < Stub
        module Application
          # @see Stub#applications
          def applications
            get('/applications').body[:data].collect { |application| to_nucleus_app(application) }
          end

          # @see Stub#application
          def application(application_id)
            to_nucleus_app(get("/application/#{app_id_by_name(application_id)}").body[:data])
          end

          # Creates the Openshift application and enables scaling by default.
          # @see Stub#create_application
          def create_application(application_entity)
            # handle runtimes / cartridges
            fail_with(:only_one_runtime) if application_entity[:runtimes].length > 1
            fail_with(:must_have_runtime) if application_entity[:runtimes].empty?
            application_entity[:cartridge] = cartridge(application_entity.delete(:runtimes)[0])

            # updates the application with a valid region identity
            retrieve_region(application_entity) if application_entity.key?(:region)

            # enable application scaling by default
            application_entity[:scale] = true unless application_entity.key?(:scale)
            created_application = post("/domains/#{app_domain}/applications", body: application_entity).body
            # now make sure we keep at least 2 deployments, allows proper identification of application state
            updated_application = put("/application/#{created_application[:data][:id]}",
                                      body: { keep_deployments: 2, auto_deploy: false }).body
            to_nucleus_app(updated_application[:data])
          end

          # @see Stub#delete_application
          def delete_application(application_id)
            delete("/applications/#{app_id_by_name(application_id)}")
          end

          private

          def app_id_by_name(application_name_or_id)
            unless application_name_or_id.length == 24 && application_name_or_id.match(/[0-9a-f]{24}/)
              response = get("/domains/#{app_domain}/applications/#{application_name_or_id}", expects: [200, 404])
              return response.body[:data][:id] if response.status == 200
            end
            # presumably already is an application id
            application_name_or_id
          end

          def cartridge(runtime)
            cartridges = get('/cartridges').body[:data]
            matched_cartridges, partial_matches = matching_cartridges(cartridges, runtime)

            fail_with(:ambiguous_runtime, [runtime, matched_cartridges]) if matched_cartridges.length > 1
            return matched_cartridges[0][:name] unless matched_cartridges.empty?
            fail_with(:invalid_runtime, [runtime]) if partial_matches.empty?

            latest = -1
            partial_matches.each { |v| latest = v if v.to_f > latest.to_f }
            matched_cartridges.push(cartridges.find { |cartridge| cartridge[:name] == "#{runtime}-#{latest}" })
            log.info("Selected cartridge '#{matched_cartridges.last[:name]}' to match '#{runtime}'")
            matched_cartridges.last[:name]
          end

          def matching_cartridges(cartridges, runtime)
            partial_matches = []
            matches = cartridges.find_all do |cartridge|
              if cartridge[:type] != 'standalone'
                false
              elsif cartridge[:name] == runtime
                true
              else
                # is the name partially valid?
                matches = cartridge[:name].match(/(\w+)-([\.\d]+)/)
                # push the version so that we can finally choose the latest version
                partial_matches.push(matches[2]) if matches[1] == runtime
                # nevertheless at first the cartridge is invalid
                false
              end
            end
            [matches, partial_matches]
          end

          def to_nucleus_app(app, gear_groups = nil, deployments = nil)
            gear_groups ||= load_gears(app[:id])
            deployments ||= load_deployments(app[:id])

            app[:release_version] = active_deployment(app, deployments)[:sha1]
            app[:state] = application_state(app, gear_groups, deployments)
            app[:web_url] = app.delete :app_url
            app[:autoscaled] = app.delete :scalable
            app[:region] = gear_groups[0][:gears][0][:region]
            app[:instances] = app.delete :gear_count
            app[:created_at] = app.delete :creation_time
            # applications can't be updated, use creation timestamp
            app[:updated_at] = app[:created_at]
            app[:active_runtime] = app.delete :framework
            # no additional runtimes, only one fixed (active) runtime per application
            app[:runtimes] = [app[:active_runtime]]
            app
          end
        end
      end
    end
  end
end
