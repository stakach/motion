require "./application"
require "gpio"

# details of any devices that are connected to the system
class Motion::Hardware < Motion::Base
  base "/api/motion/hardware"

  record GPIOLines, name : String, label : String, lines : UInt32 | UInt64 do
    include JSON::Serializable
    include YAML::Serializable
  end

  # list the available general purpose input outputs
  @[AC::Route::GET("/gpio")]
  def gpio_lines : Array(GPIOLines)
    GPIO::Chip.all.map do |chip|
      GPIOLines.new(name: chip.name, label: chip.label, lines: chip.num_lines)
    end
  end
end
