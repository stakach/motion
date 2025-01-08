require "json"
require "yaml"

module Motion
  MOTION_CONFIG_FILE = ENV["MOTION_CONFIG_FILE"]? || "./config/motion.yml"

  alias IOLine = NamedTuple(chip: String, line: Int32)
  alias Settings = NamedTuple(motion: Array(Setting))

  struct Setting
    include JSON::Serializable
    include YAML::Serializable

    Log = ::Motion::Log.for("settings")

    getter detector : IOLine
    getter active_ms : UInt32
    getter debounce_ms : UInt32

    getter outputs : Array(IOLine) = [] of IOLine
    getter webhook_uri : String? = nil
    getter webhook_method : String? = nil

    # TODO:: implement MQTT support
    getter mqtt_uri : String? = nil

    def initialize(@detector, @active_ms, @debounce_ms, @output = [] of IOLine, @webhook_uri = nil, @mqtt_uri = nil)
    end

    def self.default_settings : Settings
      {
        motion: [Setting.new({chip: "", line: 1}, 6000, 2000)],
      }
    end

    def self.ensure_config_exists
      return if File.exists?(MOTION_CONFIG_FILE)
      Log.trace { "creating config file: #{MOTION_CONFIG_FILE}" }
      dir = File.dirname(MOTION_CONFIG_FILE)
      Dir.mkdir_p(dir) unless Dir.exists?(dir)
      File.write(MOTION_CONFIG_FILE, default_settings.to_yaml)
    end

    def self.read_config : Settings
      ensure_config_exists
      Settings.from_yaml MOTION_CONFIG_FILE
    end

    def self.write_config(settings : Array(Setting))
      File.write(MOTION_CONFIG_FILE, {motion: settings})
    end
  end
end
