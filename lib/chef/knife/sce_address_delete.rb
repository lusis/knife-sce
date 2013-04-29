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
    class SceAddressDelete < Knife

      include Knife::SceBase

      banner "knife sce address delete ADDRESS [ADDRESS]"
      
      def run
        
        $stdout.sync = true

        validate!
        
        @name_args.each do |given_ip|
          connection.addresses.all.each do |address|
            if address.ip == given_ip
              ui.confirm "Are you sure you want to delete IP address #{given_ip}"
              begin
                address.destroy
              rescue
                # ignore errors
              end
              puts "Address #{given_ip} deleted."
            end
          end
        end
        
      end
    end
  end
end