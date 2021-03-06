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

class String
  def is_number?
    true if Float(self) rescue false
  end
end

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
      
      def connection_storage
        @connection_storage ||= begin
          connection_storage = Fog::Storage.new(
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
      
      def datacenter_id
        id = nil
        if locate_config_value(:datacenter).to_s.is_number?
          location = connection.locations.get( locate_config_value(:datacenter) )
          if !location.nil?
            id = location.id.to_s
          else
            ui.error("Location ID #{locate_config_value(:datacenter)} is invalid.  Use knife sce location list to learn what IDs or textual locations are available.")
            exit 1
          end
        else
          connection.locations.all.each do |location|
            if location.name.to_s.split(",").first.downcase.eql?( locate_config_value(:datacenter).downcase )
              id = location.id.to_s
            end
          end
        end
        
        if id.nil?
          ui.error("Location #{locate_config_value(:datacenter)} is invalid.  Use knife sce location list to learn what IDs or textual locations are available.")
          exit 1
        end
        
        id
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end
      
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