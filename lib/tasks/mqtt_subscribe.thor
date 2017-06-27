require "thor"
require 'mqtt'        # gem install mqtt ;  https://github.com/njh/ruby-mqtt

class MqttSubscription < Thor
  ADAFRUIT_THROTTLE_PUBLISHES_PER_SECOND = 2     # limit to N requests per second
  # Required
  require "./config/environment"
  
  ADAFRUIT_USER   = ENV['ADAFRUIT_USER'].freeze
  ADAFRUIT_IO_KEY = ENV['ADAFRUIT_IO_KEY'].freeze

  # Optional
  ADAFRUIT_HOST   = (ENV['ADAFRUIT_HOST'] || 'io.adafruit.com').freeze
  ADAFRUIT_PORT   = (ENV['ADAFRUIT_PORT'] || 1883).freeze

  ADAFRUIT_FORMAT = ENV['ADAFRUIT_FORMAT'].freeze

  # ---
  # Allow filtering to a specific format

  #ADAFRUIT_DOCUMENTED_FORMATS = %w( csv json xml ).freeze
                                        # Adafruit-MQTT doesn't support XML 160619
  ADAFRUIT_MQTT_FORMATS       = %w( csv json ).freeze

  FORMAT_REGEX_PATTERN        = %r{/(csv|json)$}

  FILTER_FORMAT = if ADAFRUIT_FORMAT.nil?
                    nil
                  elsif ADAFRUIT_MQTT_FORMATS.include?(ADAFRUIT_FORMAT)
                    "/#{ADAFRUIT_FORMAT}".freeze
                  else
                    $stderr.puts("Unsupported format (#{ADAFRUIT_FORMAT})")
                    exit 1
                  end

  ADAFRUIT_CONNECT_INFO = {
    username: ADAFRUIT_USER,
    password: ADAFRUIT_IO_KEY,
    host:     ADAFRUIT_HOST,
    port:     ADAFRUIT_PORT
  }.freeze

  ## thor methods

    desc "hello NAME", "say hello to NAME"
    def hello(name)
      option :from, :required => true
      option :yell, :type => :boolean
          output = []
          output << "from: #{options[:from]}" if options[:from]
          output << "Hello #{name}"
          output = output.join("\n")
          puts options[:yell] ? output.upcase : output
    end
    
    desc "subscribe NAME", "connect to a subscription"
    def subscribe(feed_name)
      # Subscribe
      # Connect and for each event received, print the associated value (as desired)
      #   - never returns

      topic = if feed_name.empty?
                "#{ADAFRUIT_USER}/f/#"
              else
                "#{ADAFRUIT_USER}/f/#{feed_name}"
              end

      $stderr.puts "Connecting to #{ADAFRUIT_HOST} as #{ADAFRUIT_USER} for #{topic}"

      puts "============"
      puts ADAFRUIT_CONNECT_INFO
      puts "============"
      puts feed_name
      MQTT::Client.connect(ADAFRUIT_CONNECT_INFO).connect do |client|
        client.get(topic) do |feed, value|
          #
          # Print if  a) no format specified,
          #           b) it matches the specified format, or
          #           c) the topic doesn't have a format.
          #
          #  - For the latter, if you subscribe to a particular feed, it just
          #     sends the value without any format or additional properties.
          #       e.g. 99.02
          #
          #  - Otherwise, it appends the format to the topic and sends the value
          #     along with the other properties.
          #     - Those properties depend on the format:
          #
          #       currently, 160619:
          #
          #         CSV:  VALUE,latitude,longitude,elevation
          #             e.g. 99.02,null,null,null
          #
          #         JSON: The entire server object, including internal/read-only
          #               properties (too many to list here).

          next unless FILTER_FORMAT.nil? || (feed =~ FORMAT_REGEX_PATTERN).nil? ||
                      FILTER_FORMAT == $&
          puts "#{feed}: #{value}"
        end
      end
    end
end
# MqttSubscription.start(ARGV)