require 'uri'
require 'net/http'

class Sicuro
  class Gist
    attr_accessor :url, :error, :value

    def initialize
      @url   = nil
      @error = nil
      @username = nil
      @password = nil
    end

    # Returns a String containing link to the Gist, or an error message stating
    #   why we couldn't get it.
    def value
      if url
        @url
      else
        @error
      end
    end

    # Gists (https://gist.github.com/) the result of a code evaluation.
    #
    # This is used when the output of an evaluation is beyond a specified limit.
    # The full result is pastebinned using Gist.
    #
    # credentials - An optional Hash containing two keys, :username, and :password
    #               which, if present, are used to authenticate with Github, to
    #               have the given account own the Gist.
    #
    # Sets @url to a String containing the link to the Gist, or leave it as nil.
    # If it could not Gist, it sets @error to the reason why.
    # Returns self
    def paste(stdin, stdout, stderr, description = nil)
      username = credentials[:username] || nil
      password = credentials[:password] || nil

      gist = URI.parse('https://api.github.com/gists')
      http = Net::HTTP.new(gist.host, gist.port)
      http.use_ssl = true

      headers = {}
      headers['Authorization'] = 'Basic ' + Base64.encode64("#{username}:#{password}").chop unless username.nil? or password.nil?

      response = http.post(gist.path, {
        'public' => false,
        'description' => description || '',
        'files' => {
          "input.rb" => {
            'content' => stdin
          },
          'stdout.txt' => {
            'content' => stdout
          },
          'stderr.txt' => {
            'content' => stderr
          }
        }
      }.to_json, headers)

      if response.response.code.to_i != 201
        @error = "Unable to Gist output."
      else
        @url = JSON(response.body)['html_url']
      end
      self
    end

    private
    def credentials
      # FIXME: Dummy credentials.

      {
        :username => @username,
        :password => @password
      }
    end
  end # Sicuro::Gist
end # Sicuro
