require "http"
require "tasker"
require "./state"
require "./detector"

class Motion::State::Handler
  def initialize(@settings : Setting)
    @debounce_period = settings.debounce_ms.milliseconds
    @active_period = settings.active_ms.milliseconds

    @motion = false
    @active = false
    @debouncing = false
    @last_motion = Time.unix(0_i64)
  end

  getter active_period : Time::Span
  getter debounce_period : Time::Span

  getter? motion : Bool
  getter? active : Bool
  getter? debouncing : Bool
  getter last_motion : Time

  @active_timer : Tasker::Task? = nil
  @debounce_timer : Tasker::Task? = nil

  @detector : Motion::Detector? = nil
  @outputs : Array(GPIO::Line) = [] of GPIO::Line

  def start
    detector = Motion::Detector.new(**@settings.detector)
    detector.on_motion { on_motion }
    detector.on_idle { on_idle }
    @detector = detector

    input_chip = @settings.detector[:chip]
    @settings.outputs.each do |output|
      out_chip = output[:chip]
      chip = out_chip == input_chip ? detector.chip : GPIO::Chip.new(out_chip)

      line = chip.line(output[:line])
      line.request_output
      line.set_low if line.high?
      @outputs << line
    end
  rescue error
    shutdown
    raise error
  end

  def shutdown
    deactivate
    @debouncing = true
    @detector.try(&.shutdown)
    @outputs.each(&.release)
    @outputs.clear
  end

  def on_motion : Nil
    @motion = true
    return if debouncing? || active?

    @last_motion = Time.local
    @active_timer.try(&.cancel)
    @active_timer = Tasker.in(active_period) do
      @active_timer = nil
      @debouncing = true
      @active = false

      @debounce_timer = Tasker.in(debounce_period) do
        @debounce_timer = nil
        on_motion if @motion
      end
      deactivate
    end
    activate
  end

  def on_idle : Nil
    @motion = false
  end

  def activate
    @active = true

    @outputs.each do |output|
      begin
        output.set_high
      rescue error
        Log.warn(exception: error) { "failed to set output high: #{output.chip.name}.#{output.offset}" }
      end
    end

    if webhook = @settings.webhook_uri
      method = @settings.webhook_method || "GET"
      response = HTTP::Client.exec(method.upcase, webhook)
      if !response.success?
        Log.warn { "webhook failed with #{response.status_code}: #{method} #{webhook}" }
      end
    end
  end

  def deactivate
    @active = false
    @debouncing = false

    @active_timer.try(&.cancel)
    @active_timer = nil

    @debounce_timer.try(&.cancel)
    @debounce_timer = nil

    @outputs.each(&.set_low)
  end

  def status
    {
      motion:      motion?,
      active:      active?,
      last_motion: last_motion,

      # probably an error if this is no longer monitoring
      monitoring: @detector.try(&.monitoring?) || false,
    }
  end
end
