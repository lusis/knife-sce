#
# Author:: John E. Vincent (<lusis.org+github.com@gmail.com>)
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
    class SceVlanList < Knife

      include Knife::SceBase

      banner "knife sce vlan list"
      
      def run!
        connection.vlans.all
      end
      
      def run
        $stdout.sync = true

        validate!
        
        vlan_list = [
          ui.color('Name', :bold),
          ui.color('VLAN ID', :bold),
          ui.color("Location", :bold)
        ].flatten.compact
        
        output_column_count = vlan_list.length
        
        vlans = run!
        
        vlans.each do |vlan|
          vlan_list << vlan.name.to_s
          vlan_list << connection.locations.get(vlan.location).name.to_s
          vlan_list << vlan.id.to_s
        end
        
        puts ui.list(vlan_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end
