require "benchy/version"
require 'logger'
require "thor"

module Benchy
  def self.logger
    @logger ||= Logger.new($stdout)
  end

  class Dispatcher
    attr_accessor :concurrency, :request

    def initialize(request, concurrency=1)
      @request, @concurrency = request, concurrency
    end

    def run
      workers.each(&:run)
    end

    def halt
      workers.each(&:halt)
    end

    def workers
      @workers ||= (0...concurrency).map{|n| Worker.new(request, "worker.#{n}") }
    end
  end

  class Worker
    attr_accessor :request, :name

    def initialize(request, name)
      @request, @name = request, name
    end

    # Run, and keep running!
    def run
      return if halted?

      http = request.em
      http.callback {
        Benchy.logger.info "#{name}\t| #{request.method.upcase} #{request.url} - HTTP #{http.response_header.status}"
        run
      }
      http.errback {
        Benchy.logger.debug "Connection error!"
        halt # TODO - Make this fail the ping and try again, not halt
      }
    end

    def halt
      @halted = false
    end

    def halted?
      !!@halted
    end
  end

  # Represents an HTTP Request, but can't actually be executed
  class Request
    attr_accessor :url, :method, :headers, :body

    def initialize(url, method, headers, body=nil)
      @url, @method, @headers, @body = url, method, (headers || {}), body
    end

    # Grab an instance of an Em::Http request so we can run it somewhere.
    def em
      EventMachine::HttpRequest.new(url).send(method.downcase,
        :head => default_headers.merge(headers),
        :body => body,
        :connect_timeout => 9000,    # Disable
        :inactivity_timeout => 9000  # Disable
      )
    end

    # Setup smart default headers to minimize the chances that a request gets rejected.
    def default_headers
      default_headers = {}
      default_headers['Content-Type'] = 'application/binary-octet' if body
      default_headers['Accepts']      = '*/*'
      default_headers
    end
  end

  # Parse out some command line goodness
  class CLI < Thor
    desc "benchmark URL", "Run benchmarks against server"
    method_option :body,
      :type => :string,
      :aliases => '-b',
      :desc => "Request body"
    method_option :file,
      :type => :string,
      :aliases => '-f',
      :desc => "File for request body"
    method_option :headers,
      :type => :hash,
      :aliases => '-h',
      :desc => 'HTTP headers'
    method_option :method,
      :type => :string, 
      :desc => "Request method",
      :aliases => '-m',
      :default => 'GET'
    method_option :concurrency,
      :type => :numeric,
      :desc => "Concurrent requests",
      :aliases => '-c',
      :default => 1

    def benchmark(url)
      req = Request.new(url, options[:method], options[:headers], self.class.body(options))
      EM.run { Dispatcher.new(req, options[:concurrency]).run }
    end

  private
    # Normalize the request body if its a file or a text string.
    def self.body(options)
      options[:file] ? File.read(options[:file]) : options[:body]
    end
  end
end