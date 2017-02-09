module Memcached
  module Elasticache
    module AutoDiscovery
      class Endpoint

        # Endpoint configuration
        attr_reader :host
        attr_reader :port

        # Matches Strings like "my-host.cache.aws.com:11211"
        ENDPOINT_REGEX = /([-.a-zA-Z0-9]+):(\d+)/

        STATS_COMMAND  = "stats\r\n"
        CONFIG_COMMAND = "config get cluster\r\n"

        def initialize(endpoint, options)
          ENDPOINT_REGEX.match(endpoint) do |m|
            @host = m[1]
            @port = m[2].to_i
          end
          @options = options
        end

        # A cached ElastiCache::StatsResponse
        def stats
          @stats ||= get_stats_from_remote
        end

        # A cached ElastiCache::ConfigResponse
        def config
          @config ||= get_config_from_remote
        end

        # The memcached engine version
        def engine_version
          stats.version
        end

        protected

        def with_socket(&block)
          TCPSocket.new(config_host, config_port)
        end

        def get_stats_from_remote
          data = remote_command(STATS_COMMAND)
          StatsResponse.new(data)
        end

        def get_config_from_remote
          if @options[:standalone_mode]
            ConfigResponse.new("#{@host}|#{IPSocket.getaddress(@host)}|#{@port}")
          else
            data = remote_command(CONFIG_COMMAND)
            ConfigResponse.new(data)
          end
        end

        # Send an ASCII command to the endpoint
        #
        # Returns the raw response as a String
        def remote_command(command)
          socket = TCPSocket.new(@host, @port)
          socket.puts command

          data = ""
          until (line = socket.readline) =~ /END/
            data << line
          end

          socket.close
          data
        end
      end
    end
  end
end
