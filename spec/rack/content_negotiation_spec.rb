require 'rack/content_negotiation'

RSpec.describe Rack::ContentNegotiation do
  let(:env) { Hash.new }
  let(:fallback) { double(:fallback) }

  subject(:middleware) { described_class.new(fallback) }

  context 'when not configured' do
    let(:result) { double }

    it 'calls the fallback application' do
      expect(fallback).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env)).to be(result)
    end
  end

  describe 'configuration' do
    it 'has a method to set the header name/type' do
      middleware.charset
      expect(middleware.header_name).to eq(:charset)

      middleware.encoding
      expect(middleware.header_name).to eq(:encoding)

      middleware.language
      expect(middleware.header_name).to eq(:language)

      middleware.media_type
      expect(middleware.header_name).to eq(:media_type)
    end

    it 'has a method to add an available application as the last argument' do
      called = false
      result = double
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
      result = double

      middleware.on('text/html') do |arg|
        called = true
        expect(arg).to be env
        result
      end

      expect(middleware.call(env)).to be result
      expect(called).to be true
    end

    it 'can be configured without application preference' do
      result = double
      middleware.available['text/html'] = proc { result }
      expect(middleware.call(env)).to be result
    end
  end

  context 'when configured' do
    let(:html_application) { double(:html) }
    let(:tiff_application) { double(:tiff) }
    let(:result) { double }

    subject(:middleware) do
      described_class.new(fallback) do |negotiate|
        negotiate.on('text/html', html_application)
        negotiate.on('image/tiff', tiff_application)
      end
    end

    it 'calls most preferred application' do
      expect(tiff_application).to receive(:call).with(env).and_return(result)
      expect(middleware.call(env.merge!('HTTP_ACCEPT' => 'image/*'))).to be result
    end

    context 'when there are no matching applications' do
      it 'calls the fallback application' do
        expect(fallback).to receive(:call).with(env).and_return(result)
        expect(middleware.call(env.merge!('HTTP_ACCEPT' => 'audio/tone'))).to be result
      end
    end
  end

  it 'sets the negotiated header value' do
    called = false

    middleware.on *%w( application/xhtml+xml text/html ) do |env|
      called = true
      expect(env['rack-content_negotiation.media_type']).to eq 'text/html'
    end

    middleware.call(env.merge('HTTP_ACCEPT' => 'text/*'))
    expect(called).to be true
  end
end
