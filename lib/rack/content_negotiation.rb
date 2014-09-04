require 'rack/accept_headers'

module Rack
  class ContentNegotiation
    attr_accessor :header_name, :match_unacceptable
    attr_reader :application, :available, :order

    def initialize(application)
      @application = application
      @available = Hash.new
      @header_name = :media_type
      @order = Array.new
      yield self if block_given?
    end

    [ :charset, :encoding, :language, :media_type ].each do |header_name|
      define_method(header_name) do |match_unacceptable = false|
        @header_name = header_name
        @match_unacceptable = match_unacceptable
      end
    end

    def call(env)
      headers = env['rack-accept_headers.request']

      if headers
        header = headers.__send__(@header_name)
        order = @order.empty? ? @available.keys : @order

        @available.fetch(
          env["rack-content_negotiation.#{@header_name}"] =
          header.best_of(order, @match_unacceptable),
          @application
        ).call(env)
      else
        Rack::AcceptHeaders.new(self).call(env)
      end
    end

    def on(*values, &block)
      application = block_given? ? block : values.pop
      values.each { |value| @available[value] ||= application }
      @order.concat(values)
    end
  end
end
