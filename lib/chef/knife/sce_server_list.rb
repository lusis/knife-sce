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

class Chef
  class Knife
    class SceServerList < Knife

      include Knife::SceBase

      banner "knife sce server list (options)"

      option :name,
        :short => "-n",
        :long => "--no-name",
        :boolean => true,
        :default => true,
        :description => "Do not display name tag in output"
        
      option :owner,
        :short => "-o",
        :long => "--no-owner",
        :boolean => true,
        :default => true,
        :description => "Do not display owner in output"
      
      def run!
        connection.servers.all
      end
      
      def run
        $stdout.sync = true

        validate!
        
        server_list = [
          ui.color('Instance ID', :bold),
          if config[:name]
            ui.color("Name", :bold)
          end,
          if config[:owner]
            ui.color("Owner", :bold)
          end,
          ui.color('Public IP', :bold),
          ui.color('Secondary IPs', :bold),
          ui.color('Flavor', :bold),
          ui.color('Image', :bold),
          ui.color('SSH Key', :bold),
          ui.color('Expires', :bold),
          ui.color('Request', :bold),
          ui.color('State', :bold)
          
        ].flatten.compact
        
        output_column_count = server_list.length
        
        servers = run!
        
        servers.each do |server|
          server_list << server.id.to_s
          if config[:name]
            server_list << server.name.to_s
          end
          if config[:owner]
            server_list << server.owner.to_s
          end
          server_list << server.primary_ip['hostname'].to_s
          if server.secondary_ip.empty?
            server_list << "n/a"
          else
            ips = []
            server.secondary_ip.each {|sip| ips << sip['ip'] }
            server_list << ips.join(",")
          end
          server_list << server.instance_type.to_s
          server_list << server.image_id.to_s
          server_list << server.key_name.to_s
          server_list << server.expires_at.to_s
          server_list << server.request_id.to_s
          server_list << server.state.to_s
        end
        
        puts ui.list(server_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end
