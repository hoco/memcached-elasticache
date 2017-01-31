require_relative 'spec_helper'

describe 'Memcached::Elasticache::AutoDiscovery::Endpoint' do
  let(:endpoint) do
    Memcached::Elasticache::AutoDiscovery::Endpoint.new("my-cluster.cfg.use1.cache.amazonaws.com:11211")
  end

  describe '.new' do
    it 'parses host' do
      expect(endpoint.host).to eq "my-cluster.cfg.use1.cache.amazonaws.com"
    end
    it 'parses port' do
      expect(endpoint.port).to eq 11211
    end
  end
end
