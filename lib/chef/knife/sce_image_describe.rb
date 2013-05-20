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
    class SceImageDescribe < Knife

      include Knife::SceBase

      banner "knife sce image describe IMAGE_ID [IMAGE_ID]"

      def run

        validate!

        @name_args.each do |image_id|
            
          begin
            @image = connection.images.get(image_id)
          rescue Excon::Errors::InternalServerError => e
            if image_id.is_number?
              ui.error e.inspect
              exit 1
            end
            # is not a number and we received an error, ignore, API likes numbers only, we try to fetch the image by the name
          end
          
          if @image.nil?
            connection.images.all.each do |i|
              if i.name.to_s == image_id
                @image = i
              end
            end
          end
          
          msg_pair("Image ID", @image.id.to_s)
          msg_pair("Name", @image.name.to_s)
          msg_pair("Location", connection.locations.get(@image.location).name.to_s)
          msg_pair("Description", @image.description.to_s)
          msg_pair("Visbility", @image.visibility.to_s)
          msg_pair("Platform", @image.platform.to_s)
          msg_pair("Architecture", @image.architecture.to_s)
          msg_pair("Owner", @image.owner.to_s)
          msg_pair("State", @image.state.to_s)
          msg_pair("Manifest", @image.manifest.to_s)
          msg_pair("Product codes", ":")
          @image.product_codes.each do |pc|
            msg_pair("  -> ", pc)
          end
          msg_pair("Supported instance types", ":")
          @image.supported_instance_types.each do |sit|
            msg_pair("  -> ", sit.id.to_s)
            msg_pair("     ", sit.label.to_s)
            msg_pair("     ", sit.detail.to_s)
            msg_pair("     ", "Price: #{sit.price['rate']}#{sit.price['currencyCode']}/#{sit.price['pricePerQuantity']}#{sit.price['unitOfMeasure']}")
          end
          msg_pair("Documentation", @image.documentation.to_s)
          
          puts "\n"

        end
      end

    end
  end
end
