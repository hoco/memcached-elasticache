require_relative 'spec_helper'
require 'ostruct'

describe 'Memcached::Elasticache::Endpoint' do
  let(:client) { Memcached::Elasticache::Client.new("my-cluster.cfg.use1.cache.amazonaws.com:11211", options) }

  let(:config_text) { "CONFIG cluster 0 141\r\n12\nmycluster.0001.cache.amazonaws.com|10.112.21.1|11211 mycluster.0002.cache.amazonaws.com|10.112.21.2|11211 mycluster.0003.cache.amazonaws.com|10.112.21.3|11211\n\r\n" }
  let(:response) { Memcached::Elasticache::AutoDiscovery::ConfigResponse.new(config_text) }
  let(:options) { {} }
  let(:m_client) { {} }

  before do
    allow_any_instance_of(Memcached::Elasticache::AutoDiscovery::Endpoint).to receive(:get_config_from_remote).and_return(response)
    allow(Memcached::Client).to receive(:new).and_return(m_client)
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
      expect(client.endpoint.host).to eq "my-cluster.cfg.use1.cache.amazonaws.com"
      expect(client.endpoint.port).to eq 11211
    end

    it 'stores Memcached options' do
      expect(client.options[:expires_in]).to eq 24*60*60
      expect(client.options[:namespace]).to eq "my_app"
      expect(client.options[:compress]).to be true
    end
  end

  describe '#clone' do
    subject { client.clone }

    let(:client_options) {
      {
        expires_in: 24*60*60,
        namespace: 'my_app',
        compress: true,
        ttl: 10
      }
    }
    let(:ec_options) {
      {
        refresh_interval: 10,
        max_retry_count: 5,
        local_mode: true
      }
    }
    let(:options) { client_options.merge ec_options }

    it 'clones client has same options' do
      expect(subject.options).to eq client_options
      expect(subject.instance_variable_get(:@refresh_interval)).to eq ec_options[:refresh_interval]
      expect(subject.instance_variable_get(:@max_retry_count)).to eq ec_options[:max_retry_count]
      expect(subject.instance_variable_get(:@local_mode)).to eq ec_options[:local_mode]
      expect(subject.instance_variable_get(:@default_ttl)).to eq client_options[:ttl]
    end
  end

  describe 'memcached client methods' do
    let(:key) { 'key' }
    let(:keys) { %w(key1 key2 key3) }
    let(:value) { 'value' }
    let(:ttl) { 123 }
    let(:raw) { true }
    let(:flags) { 0b0 }
    let(:offset) { 10 }

    describe '#flush' do
      subject { client.flush }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached#flush' do
        expect(m_client).to receive(:flush)
        subject
      end
    end

    describe '#set' do
      subject { client.set(key, value, ttl: ttl, raw: raw, flags: flags) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #set' do
        expect(m_client).to receive(:set).with(key, value, ttl: ttl, raw: raw, flags: flags)
        subject
      end
    end

    describe '#get' do
      subject { client.get(key, raw: raw) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #get' do
        expect(m_client).to receive(:get).with(key, raw: raw)
        subject
      end
    end

    describe '#get_multi' do
      subject { client.get_multi(keys, raw: raw) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #get_multi' do
        expect(m_client).to receive(:get_multi).with(keys, raw: raw)
        subject
      end
    end

    describe '#delete' do
      subject { client.delete(key) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #delete' do
        expect(m_client).to receive(:delete).with(key)
        subject
      end
    end

    describe '#add' do
      subject { client.add(key, value, ttl: ttl, raw: raw, flags: flags) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #add' do
        expect(m_client).to receive(:add).with(key, value, ttl: ttl, raw: raw, flags: flags)
        subject
      end
    end

    describe '#increment' do
      subject { client.increment(key, offset) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #increment' do
        expect(m_client).to receive(:increment).with(key, offset)
        subject
      end
    end

    describe '#decrement' do
      subject { client.decrement(key, offset) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #decrement' do
        expect(m_client).to receive(:decrement).with(key, offset)
        subject
      end
    end

    describe '#exist' do
      subject { client.exist(key) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #exist' do
        expect(m_client).to receive(:exist).with(key)
        subject
      end
    end

    describe '#replace' do
      subject { client.replace(key, value, ttl: ttl, raw: raw, flags: flags) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #replace' do
        expect(m_client).to receive(:replace).with(key, value, ttl: ttl, raw: raw, flags: flags)
        subject
      end
    end

    describe '#prepend' do
      subject { client.prepend(key, value, ttl: ttl, flags: flags) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #prepend' do
        expect(m_client).to receive(:prepend).with(key, value, ttl: ttl, flags: flags)
        subject
      end
    end

    describe '#append' do
      subject { client.append(key, value, ttl: ttl, flags: flags) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #append' do
        expect(m_client).to receive(:append).with(key, value, ttl: ttl, flags: flags)
        subject
      end
    end

    describe '#namespace' do
      subject { client.namespace }

      it 'calls memcached #namespace' do
        expect(m_client).to receive(:namespace)
        subject
      end
    end

    describe '#touch' do
      subject { client.touch(key, ttl) }

      it 'calls #refresh_with' do
        expect(client).to receive(:refresh_with)
        subject
      end
      it 'calls memcached #touch' do
        expect(m_client).to receive(:touch).with(key, ttl)
        subject
      end
    end

    describe '#reset' do
      subject { client.reset }

      it 'calls memcached #reset' do
        expect(m_client).to receive(:reset)
        subject
      end
    end
  end

  describe '#refresh_with' do
    subject { client.flush }

    let(:m_client) {
      Class.new {
        def flush
          'dummy'
        end
      }.new
    }

    context 'on refresh time' do
      let(:options) { { refresh_interval: -1 } }

      it 'refreshes nodes' do
        expect(client).to receive(:refresh)
        subject
      end
      it 'send command' do
        expect(m_client).to receive(:flush)
        subject
      end
    end
    context 'not on refresh time' do
      it 'doesnt refresh nodes' do
        expect(client).not_to receive(:refresh)
        subject
      end
      it 'sends command' do
        expect(m_client).to receive(:flush)
        subject
      end
    end
    context 'connection failed' do
      let(:m_client) {
        Class.new {
          def flush
            raise Memcached::ConnectionFailure
          end
        }.new
      }
      it 'refreshes nodes once' do
        expect(client).to receive(:refresh).once
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
end
