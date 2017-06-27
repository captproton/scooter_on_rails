require "thor"

class MqttPublish < Thor
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
  # desc "count", "counts from 1 to 5"
  # def count
  #   puts "1, 2, 3, 4, 5"
  # end
  #
  # desc "counttwo", "counts from 1 to 5"
  # def counttwo
  #   puts "1, 2, 3, 4, 5"
  # end
  #
  desc "publish_photocell", "publishes bogus data"
  def publish_photocell
    # Publish
    # Connect, then for each pair of args, send the second arg to the first.

    if ARGV.length > 1
      MQTT::Client.connect(ADAFRUIT_CONNECT_INFO) do |client|
        break if ARGV.length < 2

        feed  = ARGV.shift
        value = ARGV.shift.dup        # arg is frozen and MQTT wants to force encode

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

    option :from, :required => true
    option :yell, :type => :boolean
    desc "hello NAME", "say hello to NAME"
    def hello(name)
          output = []
          output << "from: #{options[:from]}" if options[:from]
          output << "Hello #{name}"
          output = output.join("\n")
          puts options[:yell] ? output.upcase : output
    end
  
end
MqttPublish.start(ARGV)