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
        k = generate_key(env)
        if k.nil?
          self.call_without_timer(env)
        else
          self.call_with_timer(k, env)
        end
      end

      def call_without_timer(env)
        @app.call(env)
      end

      def call_with_timer(key, env)
        @statsd.increment(key + ".requests")
        @statsd.time(key + ".render") do
          @app.call(env)
        end
      end

      def generate_key(env)
        s = env['PATH_INFO']
        puts(s)
        return nil if s.nil?
        s = (s == '/' ? 'index' : s.downcase.scan(/[a-z_-]+/).join('.'))
        (s.nil? || s.empty? ? nil : s)
      end

    end
  end
end