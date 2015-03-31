module Statsd
  module Rack
    # Time and record each request through a given Rack app
    # This middleware times server processing for a resource, not view render.
    class Middleware

      attr_reader :app

      def initialize(app, statsd)
        @statsd = statsd
        @app = app
      end

      def call(env)
        # Call and measure request time
        before = Time.now
        response = @app.call(env)
        response_time = Time.now - before

        # Generate key for logging
        key = generate_key(env)
        key_host = generate_host(env)
        if key 
          @statsd.increment(key + ".requests")
          @statsd.increment(key+"."+key_host + ".requests")
          @statsd.timing(key + ".render", (response_time * 1000).to_i )
          @statsd.timing(key + "." + key_host + ".render", (response_time * 1000).to_i )
        end
        # Pass the response down the stack
        response
      end

      def generate_key(env)
        if params = env["action_dispatch.request.path_parameters"]
          return 'unknown_route' unless params[:controller]
          params[:controller].to_s + '.' + params[:action].to_s
        elsif s = env['PATH_INFO']
          # If the controller and action is not found then add the key to the unknown route
          return "unknown_route"
        end
      end

      def generate_host(env)
        return "domains."+env['HTTP_HOST'].to_s.gsub(".","-")
      end

    end
  end
end