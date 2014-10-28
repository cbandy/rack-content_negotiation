require 'rack/accept_headers'

##
#
# Cuba.plugin Cuba::ContentNegotiation
#
# Cuba.define do
#   negotiate(:media_type) do |negotiate|
#     negotiate.('application/hal+json', 'application/json') do |match, header|
#     end
#
#     negotiate.('text/hml', &method(:do_some_html))
#   end
# end
#
module Cuba::ContentNegotiation

  def self.setup(application)
    application.use Rack::AcceptHeaders
  end

  def negotiate(header_name, match_unacceptable = false)
    available, order = Hash.new, Array.new

    yield lambda { |*values, &block|
      values.each { |value| available[value] ||= block }
      order.concat(values)
    }

    header = env['rack-accept_headers.request'].__send__(header_name)
    match = header.best_of(order, match_unacceptable)

    available[match].call(match, header) if match
  end

end
