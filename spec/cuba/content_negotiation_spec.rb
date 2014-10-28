require 'cuba'
require 'cuba/content_negotiation'
require 'rack/test'

RSpec.describe Cuba::ContentNegotiation do
  subject(:plugin) { described_class }

  context 'as a Cuba plugin' do
    let(:application) { double }

    it 'loads Rack::AcceptHeaders' do
      expect(application).to receive(:use).with(Rack::AcceptHeaders)
      plugin.setup(application)
    end

    it 'adds the negotiate method' do
      expect(plugin.instance_methods).to include(:negotiate)
    end
  end

  describe '#negotiate' do
    include Rack::Test::Methods

    let(:app) { Class.new(Cuba) }
    before { app.plugin(plugin) }

    let(:instance) do
      app.prototype.app.tap do |instance|
        allow(instance).to receive(:dup).and_return(instance)
      end
    end

    it 'is configured in the application context' do
      app.define { negotiate(:media_type) { verify } }

      expect(instance).to receive(:verify)

      get '/'
    end

    it 'yields a function for registering handlers' do
      app.define { negotiate(:media_type) { |register| verify(register) } }

      expect(instance).to receive(:verify) do |register|
        expect(register).to respond_to(:call)
      end

      get '/'
    end

    context 'once configured' do
      it 'executes handlers in the application context' do
        app.define { negotiate(:media_type) { |register| register.('*') { verify } } }

        expect(instance).to receive(:verify)

        get '/'
      end

      it 'yields the matched value' do
        app.define { negotiate(:media_type) { |register| register.('text/*') { |media_type| verify(media_type) } } }

        expect(instance).to receive(:verify) do |media_type|
          expect(media_type).to eq('text/*')
        end

        get '/'
      end

      it 'yields the accept header' do
        app.define { negotiate(:media_type) { |register| register.('image/png') { |_, header| verify(header) } } }

        expect(instance).to receive(:verify) do |header|
          expect(header).to be_a Rack::AcceptHeaders::Header
        end

        get '/'
      end
    end
  end
end
