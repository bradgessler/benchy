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
      @workers ||= (0..concurrency).map{|n| Worker.new(request, "worker.#{n}") }
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
        Benchy.logger.error "#{name}\t| Connection error!"
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
        :head => headers,
        :body => body,
        :connect_timeout => 9000,    # Disable
        :inactivity_timeout => 9000  # Disable
      )
    end
  end

  # Parse out some command line goodness
  class CLI < Thor
    %w[post put].each do |meth|
      desc "#{meth} URL", "#{meth.upcase} to a URL"
      method_option :body,
        :type => :string,
        :aliases => '-b',
        :desc => "Request body"
      method_option :headers,
        :type => :hash,
        :aliases => '-h',
        :desc => 'Request headers',
        :default => {
          'Content-Type' => 'application/binary-octet',
          'Accepts' => '*/*'
        }
      method_option :concurrency,
        :type => :numeric,
        :desc => "Concurrent requests",
        :aliases => '-c',
        :default => 1
      define_method meth do |url|
        request(url, meth, self.class.body(options))
      end
    end

    %w[get head delete].each do |meth|
      desc "#{meth} URL", "#{meth.upcase} to a URL"
      method_option :headers,
        :type => :hash,
        :aliases => '-h',
        :desc => 'Request headers',
        :default => {
          'Content-Type' => 'application/binary-octet',
          'Accepts' => '*/*'
        }
      method_option :concurrency,
        :type => :numeric,
        :desc => "Concurrent requests",
        :aliases => '-c',
        :default => 1
      define_method meth do |url|
        request(url, meth)
      end
    end

  private
    def request(url, method=:get, body=nil)
      req = Request.new(url, method, options[:headers], body)
      EM.run { 
        Dispatcher.new(req, options[:concurrency]).run
      }
    end

    # Normalize the request body if its specified from the CLI or if its piped in from terminal
    def self.body(options)
      options[:body] || (STDIN.read unless STDIN.tty?)
    end
  end
end