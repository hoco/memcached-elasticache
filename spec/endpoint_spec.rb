require_relative 'spec_helper'

describe 'Memcached::Elasticache::AutoDiscovery::Endpoint' do
  let(:endpoint) { Memcached::Elasticache::AutoDiscovery::Endpoint.new("#{host}:#{port}", options) }
  let(:host) { 'my-cluster.cfg.use1.cache.amazonaws.com' }
  let(:port) { 11211 }
  let(:options) { { standalone_mode: standalone_mode } }
  let(:standalone_mode) { false }

  describe '.new' do
    it 'parses host' do
      expect(endpoint.host).to eq host
    end
    it 'parses port' do
      expect(endpoint.port).to eq port
    end
  end

  describe '#config' do
    subject { endpoint.config }

    context 'standalone_mode' do
      let(:standalone_mode) { true }

      it 'returns config endpoint as the only cluster endpoint' do
        expect(subject.nodes).to eq [
          {
            host: host,
            ip:  '0.0.0.0',
            port: port
          }
        ]
      end
    end
    context 'not standalone_mode' do
      let(:standalone_mode) { false }

      it 'calls remote command' do
        expect(endpoint).to receive(:remote_command).
          with(Memcached::Elasticache::AutoDiscovery::Endpoint::CONFIG_COMMAND)
        subject
      end
    end
  end
end
