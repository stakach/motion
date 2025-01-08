require "./application"

class Motion::Status < Motion::Base
  base "/api/motion/status"

  # status of all configured IO events
  @[AC::Route::GET("/")]
  def index : NamedTuple(errors: Hash(String, String), line_status: Array(NamedTuple(motion: Bool, active: Bool, last_motion: Time, monitoring: Bool)), timestamp: Time)
    Motion::State.instance.status
  end

  # this file is built as part of the docker build
  OPENAPI = YAML.parse(File.exists?("openapi.yml") ? File.read("openapi.yml") : "{}")

  # returns the OpenAPI representation of this service
  @[AC::Route::GET("/openapi")]
  def openapi : YAML::Any
    OPENAPI
  end
end
