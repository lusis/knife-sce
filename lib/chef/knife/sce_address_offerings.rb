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
    class SceAddressOfferings < Knife

      include Knife::SceBase

      banner "knife sce address offerings (options)"
      
      option :datacenter,
        :short => "-Z LOCATION_ID",
        :long => "--data-center LOCATION_ID",
        :description => "Data center location ID, use knife sce location list to learn more about possible locations."
      
      def run
        
        $stdout.sync = true

        validate!
        
        offer_list = [
          ui.color('Offering ID', :bold),
          ui.color("Location", :bold),
          ui.color('Price', :bold)
        ].flatten.compact
        
        output_column_count = offer_list.length
        
        address_offerings = connection.list_address_offerings[:body]["addresses"]
        
        address_offerings.each do |offer|
          
          did = datacenter_id
          if did.nil? or did.eql?( offer["location"] )
          
            offer_list << offer["id"].to_s
            offer_list << connection.locations.get(offer["location"]).name
            offer_list << "#{offer['price']['rate']}#{offer['price']['currencyCode']}/#{offer['price']['pricePerQuantity']}#{offer['price']['unitOfMeasure']}"
          
          end
          
        end
        
        puts "\n"
        puts ui.list(offer_list, :uneven_columns_across, output_column_count)
        
      end
    end
  end
end