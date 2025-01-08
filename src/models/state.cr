require "./configuration"

class Motion::State
  Log = ::Motion::Log.for("state")

  class_getter instance : State { new }

  def initialize
    @config = Configuration.instance
    @last_updated = Time.unix(0_i64)
  end

  # hash of subsystem => issue description
  getter errors : Hash(String, String) = {} of String => String
  property last_updated : Time

  @handlers : Array(Handler) = [] of Handler

  def start
    @config.on_settings_changed do |settings|
      reset_state
      settings.each { |setting| monitor(setting) }
    end
    @config.watch
  end

  def reset_state
    Log.info { "resetting state" }
    shutdown
    @errors.clear
    @last_updated = Time.local
  end

  def monitor(setting : Setting)
    Log.info { "monitoring: #{setting.detector}" }
    handler = Handler.new(setting)
    handler.start
    @handlers << handler
  rescue error
    expose_error("motion.handler[#{setting.detector}]", error)
  end

  def shutdown
    @handlers.each(&.shutdown)
    @handlers.clear
  end

  def expose_error(system, error)
    @errors[system] = error.inspect_with_backtrace
  end

  def status
    {
      errors:      errors,
      line_status: @handlers.map(&.status),
      timestamp:   last_updated,
    }
  end
end

require "./state_handler"
