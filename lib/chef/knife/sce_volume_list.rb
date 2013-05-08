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
    class SceVolumeList < Knife

      include Knife::SceBase

      banner "knife sce volume list (options)"

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
        connection_storage.volumes.all
      end
      
      def run
        $stdout.sync = true

        validate!
        
        disk_list = [
          ui.color('Volume ID', :bold),
          ui.color("Instance ID", :bold),
          ui.color("Name", :bold),
          ui.color('State', :bold),
          ui.color('Size (GB)', :bold),
          ui.color('Location', :bold),
          ui.color('Format', :bold),
          ui.color('Offering', :bold),
          ui.color('Owner', :bold)
          
        ].flatten.compact
        
        output_column_count = disk_list.length
        
        volumes = run!
        
        volumes.each do |volume|
          disk_list << volume.id.to_s
          disk_list << volume.instance_id.to_s
          disk_list << volume.name.to_s
          disk_list << volume.state.to_s
          disk_list << volume.size.to_s
          disk_list << connection.locations.get(volume.location_id).name
          disk_list << volume.format.to_s
          disk_list << volume.offering_id.to_s
          disk_list << volume.owner.to_s
        end
        
        puts ui.list(disk_list, :uneven_columns_across, output_column_count)
        
      end
    end
  end
end