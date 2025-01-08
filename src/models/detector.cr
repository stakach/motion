require "gpio"
GPIO.default_consumer = "motion"

class Motion::Detector
  def initialize(chip : String, line : Int32)
    @chip = GPIO::Chip.new chip
    @line = @chip.line(line)
    @line.request_input
    @monitoring = false
    @detected = false

    spawn { monitor_input_changes }
  end

  @line : GPIO::Line

  getter? detected : Bool
  getter? monitoring : Bool
  getter chip : GPIO::Chip

  def on_motion(&@on_motion : ->)
  end

  def on_idle(&@on_idle : ->)
  end

  def shutdown
    @line.release
  end

  protected def monitor_input_changes
    @monitoring = true
    @line.on_input_change do |input_is|
      begin
        case input_is
        in .rising?
          @detected = true
          @on_motion.try &.call
        in .falling?
          @detected = false
          @on_idle.try &.call
        end
      rescue error
        Log.warn(exception: error) { "error notifying motion state change" }
      end
    end
  ensure
    @monitoring = false
  end
end
