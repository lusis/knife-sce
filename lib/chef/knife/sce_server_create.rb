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
    class SceServerCreate < Knife

      include Knife::SceBase

      deps do
        require 'fog'
        require 'readline'
        require 'chef/json_compat'
        require 'chef/knife/bootstrap'
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife sce server create (options)"

      attr_accessor :initial_sleep_delay
      attr_reader :server

      option :image,
        :short => "-I IMAGE",
        :long => "--image IMAGE",
        :description => "The SCE image ID for the server",
        :proc => Proc.new { |i| Chef::Config[:knife][:sce_image] = i }

      option :sce_flavor,
        :short => "-f FLAVOR",
        :long => "--flavor FLAVOR",
        :description => "The flavor of server (Copper, Bronze, Gold, Platinum)",
        :proc => Proc.new { |f| Chef::Config[:knife][:sce_flavor] = f }
        
      option :datacenter,
        :short => "-Z LOCATION_ID",
        :long => "--data-center LOCATION_ID",
        :description => "Data center location ID, use knife sce location list to learn more about possible locations.",
        :proc => Proc.new { |key| Chef::Config[:knife][:sce_location_id] = key }
        
      option :identity_file,
        :short => "-i IDENTITY_FILE",
        :long => "--identity-file IDENTITY_FILE",
        :description => "The SSH identity file used for authentication"

      option :associate_ip,
        :long => "--associate-ip IP_ADDRESS",
        :description => "Associate existing IP address with instance after launch"
        
      option :is_mini_ephemeral,
        :long => "--is-mini-ephemeral",
        :boolean => true,
        :default => false,
        :description => "No additional storage"
      
      option :anti_collocation_instance,
        :long => "--anti-collocation-instance INSTANCE_ID",
        :description => "No additional storage",
        :default => nil
      
      

      option :chef_node_name,
        :short => "-N NAME",
        :long => "--node-name NAME",
        :description => "The Chef node name for your new node",
        :proc => Proc.new { |key| Chef::Config[:knife][:chef_node_name] = key }

      option :sce_ssh_user,
        :short => "-x USERNAME",
        :long => "--ssh-user USERNAME",
        :description => "The ssh username",
        :default => "root"

      option :ssh_password,
        :short => "-P PASSWORD",
        :long => "--ssh-password PASSWORD",
        :description => "The ssh password"

      option :ssh_port,
        :short => "-p PORT",
        :long => "--ssh-port PORT",
        :description => "The ssh port",
        :default => "22",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_port] = key }

      option :ssh_gateway,
        :short => "-w GATEWAY",
        :long => "--ssh-gateway GATEWAY",
        :description => "The ssh gateway server",
        :proc => Proc.new { |key| Chef::Config[:knife][:ssh_gateway] = key }

      option :prerelease,
        :long => "--prerelease",
        :description => "Install the pre-release chef gems"

      option :bootstrap_version,
        :long => "--bootstrap-version VERSION",
        :description => "The version of Chef to install",
        :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

      option :distro,
        :short => "-d DISTRO",
        :long => "--distro DISTRO",
        :description => "Bootstrap a distro using a template; default is 'chef-full'",
        :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d }

      option :template_file,
        :long => "--template-file TEMPLATE",
        :description => "Full path to location of template to use",
        :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
        :default => false

      option :run_list,
        :short => "-r RUN_LIST",
        :long => "--run-list RUN_LIST",
        :description => "Comma separated list of roles/recipes to apply",
        :proc => lambda { |o| o.split(/[\s,]+/) }

      option :json_attributes,
        :short => "-j JSON",
        :long => "--json-attributes JSON",
        :description => "A JSON string to be added to the first run of chef-client",
        :proc => lambda { |o| JSON.parse(o) }

      option :host_key_verify,
        :long => "--[no-]host-key-verify",
        :description => "Verify host key, enabled by default.",
        :boolean => true,
        :default => true

      option :hint,
        :long => "--hint HINT_NAME[=HINT_FILE]",
        :description => "Specify Ohai Hint to be set on the bootstrap target.  Use multiple --hint options to specify multiple hints.",
        :proc => Proc.new { |h|
           Chef::Config[:knife][:hints] ||= {}
           name, path = h.split("=")
           Chef::Config[:knife][:hints][name] = path ? JSON.parse(::File.read(path)) : Hash.new
        }

      option :server_connect_attribute,
        :long => "--server-connect-attribute ATTRIBUTE",
        :short => "-a ATTRIBUTE",
        :description => "The EC2 server attribute to use for SSH connection",
        :default => nil

      def tcp_test_ssh(hostname, ssh_port)
        tcp_socket = TCPSocket.new(hostname, ssh_port)
        readable = IO.select([tcp_socket], nil, nil, 5)
        if readable
          Chef::Log.debug("sshd accepting connections on #{hostname}, banner is #{tcp_socket.gets}")
          yield
          true
        else
          false
        end
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      ensure
        tcp_socket && tcp_socket.close
      end
      
      def wait_for_server_active(server)
        server.wait_for { print "."; ready? }
      end
      
      def run
        
        $stdout.sync = true
        
        Fog.timeout = Chef::Config[:knife][:sce_max_timeout] || 6000

        validate!

        requested_ip = config[:associate_ip] if config[:associate_ip]

        # For VPC EIP assignment we need the allocation ID so fetch full EIP details
        # elastic_ip = connection.addresses.detect{|addr| addr if addr.public_ip == requested_elastic_ip}
        
        begin
          
          definition = create_server_def
          
          # SCE library gives me an excon response object, we have to fetch the server object ourselves:
          excon_response = connection.create_instance(definition[:name], definition[:image_id], definition[:instance_type], definition[:location], definition)
          puts excon_response.data[:body]["instances"][0]["id"].to_s
          @server = connection.servers.get(excon_response.data[:body]["instances"][0]["id"])
          
          raise "Creating a server failed." if @server.nil?
          
          msg_pair("Instance ID", @server.id.to_s)
          msg_pair("Name", @server.name.to_s)
          msg_pair("Flavor", @server.instance_type.to_s)
          msg_pair("Image", @server.image_id.to_s)
          msg_pair("Region", connection.locations.get(@server.location).name.to_s)
          msg_pair("SSH Key", @server.key_name.to_s)
          
          print "\n#{ui.color("Waiting for server", :magenta)}"
          
          msg_pair("Public DNS Name", @server.primary_ip["hostname"].to_s)
          msg_pair("Public IP Address", @server.primary_ip["ip"].to_s)
          msg_pair("Owner", @server.owner.to_s)
          msg_pair("Environment", config[:environment] || '_default')
          msg_pair("Run List", (config[:run_list] || []).join(', '))
          msg_pair("JSON Attributes",config[:json_attributes]) unless !config[:json_attributes] || config[:json_attributes].empty?
          
          @server.wait_for { print "."; ready? }
          
          wait_for_sshd(ssh_connect_host)
          
          bootstrap_for_node(@server, ssh_connect_host).run
          
        rescue Excon::Errors::PreconditionFailed => e
          ui.error e.response.data[:body]
          exit 1
        end
        
      end

      def bootstrap_for_node(server,ssh_host)
        
        # Chef::Knife:Ssh is going to use ssh_user setting from knife.rb
        # over the one that we hand to it.
        # To overrule this setting we have to override to Chef knife.rb setting.
        Chef::Config[:knife][:ssh_user] = config[:sce_ssh_user]
        
        bootstrap = Chef::Knife::Bootstrap.new
        bootstrap.name_args = [ssh_host]
        bootstrap.config[:run_list] = locate_config_value(:run_list) || []
        bootstrap.config[:ssh_user] = config[:sce_ssh_user]
        bootstrap.config[:ssh_port] = config[:ssh_port]
        bootstrap.config[:ssh_gateway] = config[:ssh_gateway]
        bootstrap.config[:identity_file] = config[:identity_file]
        bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server.id
        bootstrap.config[:prerelease] = config[:prerelease]
        bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
        bootstrap.config[:first_boot_attributes] = locate_config_value(:json_attributes) || {}
        bootstrap.config[:distro] = locate_config_value(:distro) || "chef-full"
        bootstrap.config[:use_sudo] = true unless config[:sce_ssh_user] == 'root'
        bootstrap.config[:template_file] = locate_config_value(:template_file)
        bootstrap.config[:environment] = config[:environment]
        # may be needed for vlan_mode
        bootstrap.config[:host_key_verify] = config[:host_key_verify]
        # Modify global configuration state to ensure hint gets set by
        # knife-bootstrap
        Chef::Config[:knife][:hints] ||= {}
        Chef::Config[:knife][:hints]["sce"] ||= {}
        bootstrap
      end

      def vlan_mode?
        # Amazon Virtual Private Cloud requires a subnet_id. If
        # present, do a few things differently
        !!locate_config_value(:vlan_id)
      end

      def sce_image
        @sce_image ||= connection.images.get(locate_config_value(:image))
      end

      def validate!

        super([:image, :ibm_username, :ibm_password])

        if sce_image.nil?
          ui.error("You have not provided a valid image value.")
          exit 1
        end
        
        if locate_config_value(:sce_flavor).nil?
          ui.error("No flavor provided.  Use knife sce image describe to list supported flavors for used image.")
          exit 1
        else
          
          flavor_found = false
          @sce_image.supported_instance_types.each do |sit|
            if sit.id.to_s.eql?( locate_config_value(:sce_flavor) )
              flavor_found = true
            end
          end
          if !flavor_found
            ui.error("Flavor #{config[:sce_flavor]} is not supported for image #{locate_config_value(:image)}.  Use knife sce image describe to list supported flavors for used image.")
            exit 1
          end
          
        end

      end

      def eip_scope
        if vlan_mode?
          "vpc"
        else
          "standard"
        end
      end

      def create_server_def
        server_def = {
          :name => locate_config_value(:chef_node_name),
          :image_id => locate_config_value(:image),
          :instance_type => locate_config_value(:sce_flavor),
          :location => datacenter_id.to_i,
          :key_name => File.basename(locate_config_value(:identity_file), ".*"),
          :ip => locate_config_value(:ip),
          :vlan_id => locate_config_value(:vlan_id),
          :secondary_ip => locate_config_value(:secondary_ip),
          :is_mini_ephemeral => locate_config_value(:is_mini_ephemeral),
          :configuration_data => locate_config_value(:configuration_data),
          :anti_collocation_instance => locate_config_value(:anti_collocation_instance),
        }
        server_def
      end

      def wait_for_sshd(hostname)
        config[:ssh_gateway] ? wait_for_tunnelled_sshd(hostname) : wait_for_direct_sshd(hostname, config[:ssh_port])
      end

      def wait_for_tunnelled_sshd(hostname)
        print(".")
        print(".") until tunnel_test_ssh(ssh_connect_host) {
          sleep @initial_sleep_delay ||= (vlan_mode? ? 40 : 10)
          puts("done")
        }
      end

      def tunnel_test_ssh(hostname, &block)
        gw_host, gw_user = config[:ssh_gateway].split('@').reverse
        gw_host, gw_port = gw_host.split(':')
        gateway = Net::SSH::Gateway.new(gw_host, gw_user, :port => gw_port || 22)
        status = false
        gateway.open(hostname, config[:ssh_port]) do |local_tunnel_port|
          status = tcp_test_ssh('localhost', local_tunnel_port, &block)
        end
        status
      rescue SocketError, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, Errno::ENETUNREACH, IOError
        sleep 2
        false
      rescue Errno::EPERM, Errno::ETIMEDOUT
        false
      end

      def wait_for_direct_sshd(hostname, ssh_port)
        print(".") until tcp_test_ssh(ssh_connect_host, ssh_port) {
          sleep @initial_sleep_delay ||= (vlan_mode? ? 40 : 10)
          puts("done")
        }
      end

      def ssh_connect_host
        @ssh_connect_host ||= if config[:server_connect_attribute]
          server.send(config[:server_connect_attribute])
        else
          server.ip.to_s
        end
      end
      
    end
  end
end
