require 'uri'
require 'json'

module Flipper
  module Adapters
    class Http
      class Client
        DEFAULT_HEADERS = {
          'Content-Type' => 'application/json',
          'Accept' => 'application/json',
        }.freeze

        def initialize(options = {})
          @uri = URI(options.fetch(:uri))
          @headers = DEFAULT_HEADERS.merge(options[:headers] || {})
          @basic_auth_username = options[:basic_auth_username]
          @basic_auth_password = options[:basic_auth_password]
          @read_timeout = options[:read_timeout]
          @open_timeout = options[:open_timeout]
        end

        def get(path)
          perform Net::HTTP::Get, path, @headers
        end

        def post(path, data = {})
          perform Net::HTTP::Post, path, @headers, body: JSON.generate(data)
        end

        def delete(path, data = {})
          perform Net::HTTP::Delete, path, @headers, body: JSON.generate(data)
        end

        private

        def perform(http_method, path, headers = {}, options = {})
          body = options[:body]
          uri = @uri.dup
          path_uri = URI(path)
          uri.path += path_uri.path

          if path_uri.query
            if uri.query
              uri.query += "&#{path_uri.query}"
            else
              uri.query = path_uri.query
            end
          end

          http = build_http(uri)
          request = http_method.new(uri.request_uri)
          request.initialize_http_header(headers) if headers
          request.body = body if body

          if @basic_auth_username && @basic_auth_password
            request.basic_auth(@basic_auth_username, @basic_auth_password)
          end

          http.request(request)
        end

        def build_http(uri)
          http = Net::HTTP.new(uri.host, uri.port)
          http.read_timeout = @read_timeout if @read_timeout
          http.open_timeout = @open_timeout if @open_timeout
          http
        end
      end
    end
  end
end
