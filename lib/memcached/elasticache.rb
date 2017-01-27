require 'memcached'
require 'socket'
require 'memcached/elasticache/version'
require 'memcached/elasticache/auto_discovery/endpoint'
require 'memcached/elasticache/auto_discovery/config_response'
require 'memcached/elasticache/auto_discovery/stats_response'

module Memcached
  class ElastiCache
    attr_reader :endpoint, :options, :client

    def initialize(config_endpoint, options={})
      @refresh_interval = options.delete(:refresh_interval) || 60
      @max_retry_count = options.delete(:max_retry_count) || 1
      @enable_legacy_ec = options.delete(:enable_legacy_ec) || false
      @options = options

      @last_updated_at = Time.now
      @endpoint = Memcached::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint, @enable_legacy_ec)
      @client = Memcached::Client.new(cluster_servers, @options)
    end

    def method_missing(method, *args, &block)
      if (Time.now - @last_updated_at) > @refresh_interval
        @last_updated_at = Time.now
        refresh
      end

      retry_count = 0
      begin
        @client.public_send(method, *args)
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

    private

    # List of cluster server nodes with ip addresses and ports
    # Always use host name instead of private elasticache IPs as internal IPs can change after a node is rebooted
    def cluster_servers
      endpoint.config.nodes.map { |h| "#{h[:host]}:#{h[:port]}" }
    end

    # Refresh list of cache nodes and their connections
    def refresh
      old_endpoint = endpoint
      @endpoint = Memcached::Elasticache::AutoDiscovery::Endpoint.new("#{endpoint.host}:#{endpoint.port}", @enable_legacy)

      if old_endpoint.config.nodes != @endpoint.config.nodes
        @client.reset
        @client = Memcached::Client.new(cluster_servers, @options)
      end
    end
  end
end
