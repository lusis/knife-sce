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

require 'chef/knife'

class Chef
  class Knife
    module SceBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
            require 'readline'
            require 'chef/json_compat'
          end

          option :ibm_username,
            :short => "-A USERNAME",
            :long => "--ibm-username USERNAME",
            :description => "Your IBM SCE username",
            :proc => Proc.new { |key| Chef::Config[:knife][:ibm_username] = key }

          option :ibm_password,
            :short => "-K PASSWORD",
            :long => "--ibm-password PASSWORD",
            :description => "Your SCE password",
            :proc => Proc.new { |key| Chef::Config[:knife][:ibm_password] = key }
        end
      end

      def connection
        @connection ||= begin
          connection = Fog::Compute.new(
            :provider => 'IBM',
            :ibm_username => Chef::Config[:knife][:ibm_username],
            :ibm_password => Chef::Config[:knife][:ibm_password]
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end
      
=begin
      def is_image_windows?
        image_info = connection.images.get(@server.image_id)
        return image_info.platform == 'windows'
      end
=end
      
      def validate!(keys=[:ibm_username, :ibm_password])
        errors = []
        keys.each do |k|
          pretty_key = k.to_s.gsub(/_/, ' ').gsub(/\w+/){ |w| (w =~ /(ssh)|(aws)/i) ? w.upcase  : w.capitalize }
          if Chef::Config[:knife][k].nil?
            errors << "You did not provide a valid '#{pretty_key}' value."
          end
        end
        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

    end
  end
end