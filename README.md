
```ruby
require 'rack'
require 'rack/content_negotiation'

use Rack::ContentNegotiation do |negotiate|
  negotiate.on 'text/html', HtmlApplication.new
  negotiate.on 'application/json', JsonApplication.new
end
```
