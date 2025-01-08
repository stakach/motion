require "inotify"
require "./settings"

class Motion::Configuration
  Log = ::Motion::Log.for("config")

  class_getter instance : Configuration { new }

  private def initialize
  end

  getter settings : Array(Setting) { Setting.read_config[:motion] }

  @mutex : Mutex = Mutex.new

  def on_settings_changed(&@settings_changed : Array(Setting) ->)
  end

  def watch : Nil
    Setting.ensure_config_exists

    watched_file = File.expand_path(MOTION_CONFIG_FILE)
    Log.trace { "watching file: #{watched_file}" }

    Inotify.watch(MOTION_CONFIG_FILE) do |event|
      Log.info { "new config change event: #{event}" }
      spawn { new_config }
    end

    # apply the config
    new_config
  end

  def read_config : Array(Setting)
    Setting.read_config[:motion]
  rescue error
    Log.warn(exception: error) { "failed to read configuration file, applying default" }
    Setting.default_settings[:motion]
  end

  def new_config : Nil
    @mutex.synchronize do
      Log.info { "applying new settings" }

      settings = read_config
      # ensure old pipelines are configured
      @settings = settings
      @settings_changed.try &.call(settings)
    end
  rescue error
    Log.warn(exception: error) { "failed to apply configuration change" }
  end
end
