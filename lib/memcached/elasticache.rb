require 'memcached'
require 'socket'
require 'memcached/elasticache/version'
require 'memcached/elasticache/auto_discovery/endpoint'
require 'memcached/elasticache/auto_discovery/config_response'
require 'memcached/elasticache/auto_discovery/stats_response'

module Memcached
  module Elasticache
    class Client
      attr_reader :endpoint, :options

      # Initialize ElastiCache client
      # @param [String] config_endpoint ElastiCache config endpoint strings like "my-host.cache.aws.com:11211"
      # @option [Integer] :refresh_interval second-scale interval of refreshing cluster endpoints
      # @option [Integer] :max_retry_count max retry times to command and refresh cluster endpoints
      # @option [Boolean] :local_mode if local_mode is true, the client always treats the config endpoint as the only cluster endpoint (for non-ElastiCache memcached)
      # @option [Integer] :ttl default TTL used by Memcached::Client
      def initialize(config_endpoint, options={})
        @refresh_interval = options.delete(:refresh_interval) || 60
        @max_retry_count = options.delete(:max_retry_count) || 1
        @local_mode = options.delete(:local_mode) || false
        @default_ttl = options[:ttl] || 0
        @options = options

        @last_updated_at = Time.now
        @endpoint = Memcached::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint, endpoint_options)
        @client = Memcached::Client.new(cluster_servers, @options)
      end

      def clone
        options = @options.dup.merge(
          refresh_interval: @refresh_interval,
          max_retry_count: @max_retry_count,
          local_mode: @local_mode
        )
        Memcached::Elasticache::Client.new(config_endpoint, options)
      end

      # memcached client methods

      def flush
        refresh_with { @client.flush }
      end

      def set(key, value, ttl: @default_ttl, raw: false, flags: Memcached::Client::FLAGS)
        refresh_with { @client.set(key, value, ttl: ttl, raw: raw, flags: flags) }
      end

      def get(key, raw: nil)
        refresh_with { @client.get(key, raw: raw) }
      end

      def get_multi(keys, raw: nil)
        refresh_with { @client.get_multi(keys, raw: raw) }
      end

      def delete(key)
        refresh_with { @client.delete(key) }
      end

      def add(key, value, ttl: @default_ttl, raw: false, flags: Memcached::Client::FLAGS)
        refresh_with { @client.add(key, value, ttl: ttl, raw: raw, flags: flags) }
      end

      def increment(key, offset = 1)
        refresh_with { @client.increment(key, offset) }
      end

      def decrement(key, offset = 1)
        refresh_with { @client.decrement(key, offset) }
      end

      def exist(key)
        refresh_with { @client.exist(key) }
      end

      def replace(key, value, ttl: @default_ttl, raw: false, flags: Memcached::Client::FLAGS)
        refresh_with { @client.replace(key, value, ttl: ttl, raw: raw, flags: flags) }
      end

      def prepend(key, value, ttl: @default_ttl, flags: Memcached::Client::FLAGS)
        refresh_with { @client.prepend(key, value, ttl: ttl, flags: flags) }
      end

      def append(key, value, ttl: @default_ttl, flags: Memcached::Client::FLAGS)
        refresh_with { @client.append(key, value, ttl: ttl, flags: flags) }
      end

      def namespace
        @client.namespace
      end

      def touch(key, ttl = @default_ttl)
        refresh_with { @client.touch(key, ttl) }
      end

      def reset
        @client.reset
      end

      private

      def refresh_with
        if (Time.now - @last_updated_at) > @refresh_interval
          @last_updated_at = Time.now
          refresh
        end

        retry_count = 0
        begin
          yield
        rescue Memcached::ConnectionFailure => e
          if retry_count < @max_retry_count
            retry_count += 1
            refresh
            retry
          else
            raise e
          end
        end
      end

      # List of cluster server nodes with ip addresses and ports
      # Always use host name instead of private elasticache IPs as internal IPs can change after a node is rebooted
      def cluster_servers
        endpoint.config.nodes.map { |h| "#{h[:host]}:#{h[:port]}" }
      end

      # Refresh list of cache nodes and their connections
      def refresh
        old_endpoint = endpoint
        @endpoint = Memcached::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint, endpoint_options)

        if old_endpoint.config.nodes != @endpoint.config.nodes
          @client.reset
          @client = Memcached::Client.new(cluster_servers, @options)
        end
      end

      def config_endpoint
        "#{endpoint.host}:#{endpoint.port}"
      end

      def endpoint_options
        { local_mode: @local_mode }
      end
    end
  end
end
