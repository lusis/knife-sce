#
# Author:: Rad Gruchalski (<radek@gruchalski.com>)
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'chef/knife/sce_base'

# These two are needed for the '--purge' deletion case
require 'chef/node'
require 'chef/api_client'

class Chef
  class Knife
    class SceServerDelete < Knife

      include Knife::SceBase

      banner "knife sce server delete SERVER [SERVER] (options)"

      attr_reader :server

      option :purge,
        :short => "-P",
        :long => "--purge",
        :boolean => true,
        :default => false,
        :description => "Destroy corresponding node and client on the Chef Server, in addition to destroying the SCE node itself.  Assumes node and client have the same name as the server (if not, add the '--node-name' option)."

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The name of the node and client to delete, if it differs from the server name.  Only has meaning when used with the '--purge' option."

      # Extracted from Chef::Knife.delete_object, because it has a
      # confirmation step built in... By specifying the '--purge'
      # flag (and also explicitly confirming the server destruction!)
      # the user is already making their intent known.  It is not
      # necessary to make them confirm two more times.
      def destroy_item(klass, name, type_name)
        begin
          object = klass.load(name)
          object.destroy
          ui.warn("Deleted #{type_name} #{name}")
        rescue Net::HTTPServerException
          ui.warn("Could not find a #{type_name} named #{name} to delete!")
        end
      end

      def run

        validate!

        @name_args.each do |instance_id|

          begin
            
            @server = connection.servers.get(instance_id)
            
            if @server.nil?
              connection.servers.all.each do |s|
                if s.name.to_s == instance_id
                  @server = s
                end
              end
            end
            
            msg_pair("Instance ID", @server.id.to_s)
            msg_pair("Name", @server.name.to_s)
            msg_pair("Flavor", @server.instance_type.to_s)
            msg_pair("Image", @server.image_id.to_s)
            msg_pair("Region", connection.locations.get(@server.location_id.to_i).name.to_s)
            msg_pair("SSH Key", @server.key_name.to_s)
            msg_pair("Public DNS Name", @server.primary_ip["hostname"].to_s)
            msg_pair("Public IP Address", @server.primary_ip["ip"].to_s)
            msg_pair("Expires at", @server.expires_at.to_s)

            puts "\n"
            confirm("Do you really want to delete this server")
            
            begin
              @server.destroy
            rescue Excon::Errors::PreconditionFailed => e
              if e.data[:body].index("Active or Failed").nil?
                ui.error e.data[:body].to_s
                exit 1
              end
            end

            ui.warn("Deleted server #{@server.id}")

            if config[:purge]
              thing_to_delete = config[:chef_node_name] || instance_id
              destroy_item(Chef::Node, thing_to_delete, "node")
              destroy_item(Chef::ApiClient, thing_to_delete, "client")
            else
              ui.warn("Corresponding node and client for the #{instance_id} server were not deleted and remain registered with the Chef Server")
            end

          rescue NoMethodError
            ui.error("Could not locate server '#{instance_id}'.  Please verify it was provisioned.")
          end
        end
      end

    end
  end
end
