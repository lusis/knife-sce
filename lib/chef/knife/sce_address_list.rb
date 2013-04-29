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
    class SceAddressList < Knife

      include Knife::SceBase

      banner "knife sce address list"
      
      def run!
        connection.addresses.all
      end
      
      def run
        $stdout.sync = true

        validate!
        
        address_list = [
          ui.color('Address ID', :bold),
          ui.color("Location", :bold),
          ui.color("IP", :bold),
          ui.color('State', :bold),
          ui.color('Instance ID', :bold),
          ui.color('Offering ID', :bold),
          ui.color('VLAN ID', :bold),
          ui.color('Hostname', :bold),
          ui.color('Owner', :bold)
          
        ].flatten.compact
        
        output_column_count = address_list.length
        
        addresses = run!
        
        addresses.each do |address|
          address_list << address.id.to_s
          address_list << connection.locations.get(address.location).name.to_s
          address_list << address.ip.to_s
          address_list << address.state.to_s
          address_list << address.instance_id.to_s
          address_list << address.offering_id.to_s
          address_list << address.vlan_id.to_s
          address_list << address.hostname.to_s
          address_list << address.owner.to_s
        end
        
        puts ui.list(address_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end