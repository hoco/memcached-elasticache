require 'memcached'
require 'socket'
require 'memcached/elasticache/version'
require 'memcached/elasticache/auto_discovery/endpoint'
require 'memcached/elasticache/auto_discovery/config_response'
require 'memcached/elasticache/auto_discovery/stats_response'

class Memcached
  class ElastiCache
    attr_reader :endpoint, :options
    
    def initialize(config_endpoint, options={})
      @endpoint = Memcached::Elasticache::AutoDiscovery::Endpoint.new(config_endpoint)
      @options = options
      @refresh_interval = options[:refresh_interval] || 60
      @last_updated_at = Time.now
      @client = Memcached.new(cluster_servers, @options)
    end

    def method_missing(method, *args, &block)
      if (Time.now - @last_updated_at) > @refresh_interval
        @last_updated_at = Time.now
        refresh
      end
      @client.public_send(method, *args)
    end

    private

    # List of cluster server nodes with ip addresses and ports
    # Always use host name instead of private elasticache IPs as internal IPs can change after a node is rebooted
    def cluster_servers
      endpoint.config.nodes.map{ |h| "#{h[:host]}:#{h[:port]}" }
    end

    # Refresh list of cache nodes and their connections
    def refresh
      old_endpoint = endpoint
      @endpoint = Memcached::Elasticache::AutoDiscovery::Endpoint.new("#{endpoint.host}:#{endpoint.port}")

      @client.reset(cluster_servers) if old_endpoint.config != @endpoint.config
    end
  end
end
