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
    class SceKeyCreate < Knife

      include Knife::SceBase

      banner "knife sce key create KEYNAME"
      
      def run!(key_name)
        @key = connection.keys.create(:name => key_name)
        @key
      end
      
      def run
        
        $stdout.sync = true

        validate!
        
        @key = run!(config[:name])
        
        msg_pair("Name", @key.name.to_s)
        msg_pair("Default", (@key.default ? "Yes" : "No"))
        msg_pair("Key", @key.public_key.to_s)
        
      end
      
      def validate!
        
        super
        
        raise "No key name specified." if @name_args.length == 0
        config[:name] = @name_args[0]
        
      end
      
    end
  end
end