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
    class SceKeyList < Knife

      include Knife::SceBase

      banner "knife sce key list (options)"
      
      def run!
        connection.keys.all
      end
      
      def run
        
        $stdout.sync = true

        validate!
        
        keys = run!
        
        key_list = [
          ui.color('Name', :bold),
          ui.color('Default', :bold),
          ui.color("Modified at", :bold),
          ui.color('Instances', :bold)
        ].flatten.compact
        
        output_column_count = key_list.length
        
        keys.each do |k|
          key_list << k.name.to_s
          key_list << (k.default ? "*" : " ")
          key_list << Time.at(k.modified_at/1000).to_datetime.to_s
          key_list << k.instance_ids.join(", ").to_s
        end
        
        puts ui.list(key_list, :uneven_columns_across, output_column_count)
        
      end
    end
  end
end