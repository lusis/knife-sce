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
    class SceVolumeDelete < Knife

      include Knife::SceBase

      banner "knife sce volume delete VOLUME [VOLUME]"
      
      def run
        
        $stdout.sync = true

        validate!
        
        @name_args.each do |v|
          connection_storage.volumes.all.each do |volume|
            if volume.id == v || volume.name == v
              ui.confirm "Are you sure you want to delete volume #{volume.name}"
              begin
                volume.destroy
              rescue
                # ignore errors
              end
              puts "Volume #{volume.name} deleted."
            end
          end
        end
        
      end
    end
  end
end