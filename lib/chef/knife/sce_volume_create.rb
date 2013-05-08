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
    class SceVolumeCreate < Knife

      include Knife::SceBase

      banner "knife sce volume create (options)"

      option :name,
        :short => "-N NAME",
        :long => "--name NAME",
        :description => "Name of the volume to create."
        
      option :datacenter,
        :short => "-Z LOCATION_ID",
        :long => "--data-center LOCATION_ID",
        :description => "Data center location ID, use knife sce location list to learn more about possible locations.",
        :proc => Proc.new { |key| Chef::Config[:knife][:sce_location_id] = key }
        
      option :offering_id,
        :short => "-O OFFER_ID",
        :long => "--offering-id OFFER_ID",
        :description => "..."
        
      option :size,
        :short => "-S SIZE",
        :long => "--size SIZE",
        :description => "Size "
        
      option :format,
        :short => "-F FORMAT",
        :long => "--format FORMAT",
        :description => "...",
        :default => "ext3"
      
      def run
        
        $stdout.sync = true
        
        Fog.timeout = Chef::Config[:knife][:sce_max_timeout] || 6000

        validate!
        
        disk_launch_desc = {
          :name => config[:name],
          :offering_id => config[:offering_id],
          :format => config[:format].upcase,
          :location_id => config[:datacenter],
          :size => config[:size]
        }
        
        puts "Creating volume #{config[:name]}"
        
        volume = connection_storage.volumes.create(disk_launch_desc)
        
        puts "Volume #{config[:name]} created, volume ID is #{volume.id}. Waiting for ready..."
        
        volume.wait_for { ready? }
        
        puts "Volume #{config[:name]} ready to use."
        
        puts "\n"
        
        volume.id.to_s
        msg_pair("Volume ID", volume.id.to_s )
        msg_pair("Name", volume.name.to_s )
        msg_pair("State", volume.state.to_s )
        msg_pair("Size", volume.size.to_s )
        msg_pair("Location", connection.locations.get(volume.location_id).name )
        msg_pair("Format", volume.format.to_s )
        msg_pair("Offering ID", volume.offering_id.to_s )
        msg_pair("Owner", volume.owner.to_s )
        
      end

      def validate!

        super([:ibm_username, :ibm_password])
        
=begin
        # Add more validation
=end

      end
      
    end
  end
end
