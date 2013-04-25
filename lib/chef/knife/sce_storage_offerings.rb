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
    class SceStorageOfferings < Knife

      include Knife::SceBase

      banner "knife sce storage offerings (options)"
      
      option :datacenter,
        :short => "-Z LOCATION_ID",
        :long => "--data-center LOCATION_ID",
        :description => "Data center location ID, use knife sce location list to learn more about possible locations."
      
      def run
        
        $stdout.sync = true

        validate!
        
        offer_list = [
          ui.color('Offering ID', :bold),
          ui.color("Name", :bold),
          ui.color("Label", :bold),
          ui.color("Location", :bold),
          ui.color('Supported sizes', :bold),
          ui.color('Supported formats', :bold),
          ui.color('Price', :bold)
        ].flatten.compact
        
        output_column_count = offer_list.length
        
        connection_storage.offerings.all.each do |offer|
          
          formats = []
          offer.supported_formats.each do |format|
            formats << format["id"]
          end
          sizes = offer.supported_sizes.split(",")
          
          if config[:datacenter].nil? or config[:datacenter] == offer.location
          
            offer_list << offer.id.to_s
            offer_list << offer.name.to_s
            offer_list << offer.label.to_s
            offer_list << connection.locations.get(offer.location).name
            offer_list << "#{sizes[0].to_s}GB"
            offer_list << formats.join(", ")
            offer_list << "#{offer.price['rate']}#{offer.price['currencyCode']}/#{offer.price['pricePerQuantity']}#{offer.price['unitOfMeasure']}"
          
            (1...sizes.length).each do |index|
              offer_list << " "
              offer_list << " "
              offer_list << " "
              offer_list << " "
              offer_list << "#{sizes[index].to_s}GB"
              offer_list << " "
              offer_list << " "
            end
          
          end
          
        end
        
        puts "\n"
        puts ui.list(offer_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end