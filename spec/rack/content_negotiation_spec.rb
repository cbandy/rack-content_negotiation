require 'rack/content_negotiation'

RSpec.describe Rack::ContentNegotiation do
  let(:default) { double(:default) }
  let(:env) { Hash.new }

  subject(:middleware) { described_class.new(default) }

  context 'when not configured' do
    let(:result) { double }

    it 'calls the default application' do
      expect(default).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env)).to be(result)
    end
  end

  describe 'configuration' do
    let(:result) { double }

    it 'has a method to add an available application as the last argument' do
      called = false
      application = lambda do |arg|
        called = true
        expect(arg).to be env
        result
      end

      middleware.on('text/html', application)

      expect(middleware.call(env)).to be result
      expect(called).to be true
    end

    it 'has a method to add an available application as a block' do
      called = false

      middleware.on('text/html') do |arg|
        called = true
        expect(arg).to be env
        result
      end

      expect(middleware.call(env)).to be result
      expect(called).to be true
    end
  end

  context 'when configured with available values' do
    subject(:middleware) do
      described_class.new(default) do |negotiate|
        negotiate.for('text/html', 'image/tiff')
      end
    end

    %w( image/* audio/tone ).each do |type|
      it 'calls the default application' do
        result = double
        expect(default).to receive(:call).with(env).and_return(result)
        expect(middleware.call(env.merge!('HTTP_ACCEPT' => type))).to be result
      end
    end

    it 'sets the negotiated header value' do
      expect(default).to receive(:call) do |env|
        expect(env['rack-content_negotiation.media_type']).to eq 'image/tiff'
      end

      middleware.call(env.merge('HTTP_ACCEPT' => 'image/*'))
    end

    context 'when there are no matching values' do
      it 'does not set a negotiated header value' do
        expect(default).to receive(:call) do |env|
          expect(env['rack-content_negotiation.media_type']).to be nil
        end

        middleware.call(env.merge('HTTP_ACCEPT' => 'audio/tone'))
      end
    end
  end

  context 'when configured with applications' do
    let(:html_application) { double(:html) }
    let(:tiff_application) { double(:tiff) }
    let(:result) { double }

    subject(:middleware) do
      described_class.new(default) do |negotiate|
        negotiate.on('text/html', html_application)
        negotiate.on('image/tiff', tiff_application)
      end
    end

    it 'calls most preferred application' do
      expect(tiff_application).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env.merge!('HTTP_ACCEPT' => 'image/*'))).to be result
    end

    it 'sets the negotiated header value' do
      expect(tiff_application).to receive(:call) do |env|
        expect(env['rack-content_negotiation.media_type']).to eq 'image/tiff'
      end

      middleware.call(env.merge('HTTP_ACCEPT' => 'image/*'))
    end

    context 'when there are no matching applications' do
      it 'calls the default application' do
        expect(default).to receive(:call).with(env).and_return(result)
        expect(middleware.call(env.merge!('HTTP_ACCEPT' => 'audio/tone'))).to be result
      end

      it 'does not set a negotiated header value' do
        expect(default).to receive(:call) do |env|
          expect(env['rack-content_negotiation.media_type']).to be nil
        end

        middleware.call(env.merge('HTTP_ACCEPT' => 'audio/tone'))
      end
    end
  end
end
