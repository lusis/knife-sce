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
    class SceAddressCreate < Knife

      include Knife::SceBase

      banner "knife sce address create LOCATION"
      
      def run
        
        $stdout.sync = true

        validate!
        
        location = nil
        begin
          location = connection.locations.get(@name_args[0])
        rescue
          ui.error "Location #{@name_args[0]} is not a valid location ID."
          exit 1
        end
        
        if location.nil?
          ui.error "Location #{@name_args[0]} is not a valid location ID."
          exit 1
        end
        
        offering_id = nil
        address_offerings = connection.list_address_offerings[:body]["addresses"]
        address_offerings.each do |offer|
          if offer["location"] == location.id
            offering_id = offer["id"]
          end
        end
        
        if offering_id.nil?
          ui.error "Could not fetch offer ID for location #{location.name}"
          exit 1
        end
        
        puts "Creating an IP address at #{location.name} for offer ID #{offering_id}"
        
        response = connection.create_address(@name_args[0], offering_id)
        if response.is_a?(Excon::Response)
          puts "\n"
          puts "New IP address allocated, IP value will be available for you shortly."
          puts "Please use 'knife sce address list' and check the 'State' of allocation '#{response[:body]["id"]}'."
          puts "Your IP is available for use when it is in state 'Free'."
          puts "\n"
        else
          ui.error response[:body].to_s
          exit 1
        end
        
      end
    end
  end
end