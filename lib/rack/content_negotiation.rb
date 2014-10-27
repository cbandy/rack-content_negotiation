require 'rack/accept_headers'

##
#
# use Rack::ContentNegotiation, :media_type do |negotiate|
#   negotiate.on('application/hal+json', 'application/json') do |env|
#   end
#
#   negotiate.on('text/html', &html_application)
# end
#
module Rack::ContentNegotiation

  def self.new(application, header_name = :media_type, match_unacceptable = false)
    Middleware.new(application, header_name, match_unacceptable).tap { |m| yield m if block_given? }
  end

  class Matcher
    attr_reader :available, :header_name, :match_unacceptable

    def initialize(header_name, match_unacceptable)
      @available = Array.new
      @header_name = header_name
      @match_unacceptable = match_unacceptable
    end

    def call(accept_headers)
      accept_headers.__send__(@header_name).best_of(@available, @match_unacceptable)
    end
  end

  class Middleware
    attr_reader :application, :available

    def initialize(application, header_name, match_unacceptable)
      @application = application
      @available = Hash.new(application)
      @matcher = Matcher.new(header_name, match_unacceptable)
    end

    def call(env)
      headers = env['rack-accept_headers.request']

      if headers
        match = env["rack-content_negotiation.#{@matcher.header_name}"] = @matcher.call(headers)
        @available[match].call(env)
      else
        Rack::AcceptHeaders.new(self).call(env)
      end
    end

    def for(*values)
      @matcher.available.concat(values)
    end

    def on(*values, &block)
      application = block_given? ? block : values.pop
      values.each { |value| @available[value] = application }
      @matcher.available.concat(values)
    end
  end

end
