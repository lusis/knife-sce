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
    class SceLocationList < Knife

      include Knife::SceBase

      banner "knife sce location list (options)"
      
      option :description,
        :short => "-L",
        :long => "--with-description",
        :boolean => true,
        :default => false,
        :description => "Display description of the location"
        
      option :capabilities,
        :short => "-C",
        :long => "--with-capabilities",
        :boolean => true,
        :default => false,
        :description => "Display capabilities"
      
      def run!
        connection.locations.all
      end
      
      def run
        $stdout.sync = true

        validate!
        
        location_list = [
          ui.color('Location ID', :bold),
          ui.color("Name", :bold),
          ui.color('Location', :bold),
          if config[:description]
            ui.color('Description', :bold)
          end,
          if config[:capabilities]
            ui.color('Capabilities', :bold)
          end
        ].flatten.compact
        
        output_column_count = location_list.length
        
        locations = run!
        
        locations.each do |location|
          location_list << location.id.to_s
          location_list << location.name.to_s
          location_list << location.location.to_s
          if config[:description]
            location_list << location.description.to_s
          end
          if config[:capabilities]
            if location.capabilities.length > 0
              tabs = "\t"
              tabs = "#{tabs}\t" if location.capabilities[0]["id"].to_s.length < 25
              location_list << "#{location.capabilities[0]["id"].to_s}:#{tabs}#{location.capabilities[0]["entries"].to_s}"
            else
              location_list << " "
            end
          end
          
          if config[:capabilities]
            (1...location.capabilities.length).each do |index|
              location_list << " "
              location_list << " "
              location_list << " "
              if config[:description]
                location_list << " "
              end
              tabs = "\t"
              tabs = "#{tabs}\t" if location.capabilities[index]["id"].to_s.length < 25
              location_list << "#{location.capabilities[index]["id"].to_s}:#{tabs}#{location.capabilities[index]["entries"].to_s}"
            end
          end
          
        end
        
        puts ui.list(location_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end