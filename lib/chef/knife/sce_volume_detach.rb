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
    class SceVolumeDetach < Knife

      include Knife::SceBase

      banner "knife sce volume detach INSTANCE_ID VOLUME [VOLUME]"
      
      def run
        
        $stdout.sync = true

        validate!
        
        (1..@name_args.length-1).each do |idx|
          puts "Detaching volume #{@name_args[idx]} from #{name_args[0]}"
          begin
            res = connection.modify_instance(@name_args[0], {
              "type" => "detach",
              "storageID" => @name_args[idx]
            })
            puts "Detach request for volume #{@name_args[idx]} issued."
          rescue Exception => e
            ui.error("There was an error while detaching volume #{@name_args[idx]}.  Error is #{e.to_s}")
          end
        end
        
      end
    end
  end
end