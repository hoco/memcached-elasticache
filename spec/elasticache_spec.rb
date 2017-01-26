require_relative 'spec_helper'

describe 'Memcached::ElastiCache::Endpoint' do
  let(:cache) do
    options = {
      :expires_in => 24*60*60,
      :namespace => "my_app",
      :compress => true
    }
    Memcached::ElastiCache.new("my-cluster.cfg.use1.cache.amazonaws.com:11211", options)
  end

  let(:config_text) { "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\n" }
  let(:response) { Memcached::Elasticache::AutoDiscovery::ConfigResponse.new(config_text) }

  before do
    Memcached::Elasticache::AutoDiscovery::Endpoint.any_instance.should_receive(:get_config_from_remote).and_return(response)
    Memcached.should_receive(:new).and_return('dummy_client')
  end

  describe '.new' do
    it 'builds endpoint' do
      cache.endpoint.host.should == "my-cluster.cfg.use1.cache.amazonaws.com"
      cache.endpoint.port.should == 11211
    end
    
    it 'stores Memcached options' do
      cache.options[:expires_in].should == 24*60*60
      cache.options[:namespace].should == "my_app"
      cache.options[:compress].should == true
    end
  end

  describe '#method_missing' do
  end
end
