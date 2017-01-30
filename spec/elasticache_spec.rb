require_relative 'spec_helper'
require 'ostruct'

describe 'Memcached::ElastiCache::Endpoint' do
  let(:cache) { Memcached::ElastiCache.new("my-cluster.cfg.use1.cache.amazonaws.com:11211", options) }

  let(:config_text) { "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\n" }
  let(:response) { Memcached::Elasticache::AutoDiscovery::ConfigResponse.new(config_text) }
  let(:options) { {} }
  let(:dummy_client) {
    Class.new {
      def dummy_command
        'dummy'
      end
    }.new
  }

  before do
    allow_any_instance_of(Memcached::Elasticache::AutoDiscovery::Endpoint).to receive(:get_config_from_remote).and_return(response)
    allow(Memcached::Client).to receive(:new).and_return(dummy_client)
  end

  describe '.new' do
    let(:options) {
      {
        expires_in: 24*60*60,
        namespace: 'my_app',
        compress: true
      }
    }
    it 'builds endpoint' do
      expect(cache.endpoint.host).to eq "my-cluster.cfg.use1.cache.amazonaws.com"
      expect(cache.endpoint.port).to eq 11211
    end

    it 'stores Memcached options' do
      expect(cache.options[:expires_in]).to eq 24*60*60
      expect(cache.options[:namespace]).to eq "my_app"
      expect(cache.options[:compress]).to be true
    end
  end

  describe '#method_missing' do
    subject { cache.dummy_command }

    context 'on refresh time' do
      let(:options) { { refresh_interval: -1 } }

      it 'refreshes nodes' do
        expect(cache).to receive(:refresh)
        subject
      end
      it 'send command' do
        expect(cache).to receive(:dummy_command)
        subject
      end
    end
    context 'not on refresh time' do
      it 'doesnt refresh nodes' do
        expect(cache).not_to receive(:refresh)
        subject
      end
      it 'sends command' do
        expect(cache).to receive(:dummy_command)
        subject
      end
    end

    context 'connection failed' do
      let(:dummy_client) {
        Class.new {
          def dummy_command
            raise Memcached::ConnectionFailure
          end
        }.new
      }

      it 'refreshes nodes once' do
        expect(cache).to receive(:refresh).once
        begin
          subject
        rescue
        end
      end

      it 'raises error' do
        expect { subject }.to raise_error(Memcached::ConnectionFailure)
      end
    end
  end

  describe '#clone' do
    subject { cache.clone }

    let(:client_options) {
      {
        expires_in: 24*60*60,
        namespace: 'my_app',
        compress: true
      }
    }
    let(:ec_options) {
      {
        refresh_interval: 10,
        max_retry_count: 5,
        enable_legacy_ec: true
      }
    }
    let(:options) { client_options.merge ec_options }

    it 'clones client has same options' do
      expect(subject.options).to eq client_options
      expect(subject.instance_variable_get(:@refresh_interval)).to eq ec_options[:refresh_interval]
      expect(subject.instance_variable_get(:@max_retry_count)).to eq ec_options[:max_retry_count]
      expect(subject.instance_variable_get(:@enable_legacy_ec)).to eq ec_options[:enable_legacy_ec]
    end
  end
end
