require "thor"
require 'mqtt'        # gem install mqtt ;  https://github.com/njh/ruby-mqtt

class MqttPublication < Thor
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
    
    desc "send feed_name [value or payload]/[format if any]", "publish to a subscription"
    def send(feed_name, value_arg)
      MQTT::Client.connect(ADAFRUIT_CONNECT_INFO) do |client|

        feed  = feed_name
        value = value_arg        # arg is frozen and MQTT wants to force encode

        topic = if ADAFRUIT_FORMAT.nil? || feed.end_with?(ADAFRUIT_FORMAT)
                  "#{ADAFRUIT_USER}/f/#{feed}"
                else
                  "#{ADAFRUIT_USER}/f/#{feed}/#{ADAFRUIT_FORMAT}"
                end

        $stderr.puts "Publishing #{value} to #{topic} @ #{ADAFRUIT_HOST}"

        client.publish(topic, value)

        sleep(1.0 / ADAFRUIT_THROTTLE_PUBLISHES_PER_SECOND)
      end

      exit 0

    end
end
# MqttSubscription.start(ARGV)