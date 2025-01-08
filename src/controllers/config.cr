require "./application"

# methods for viewing and updating the configuration of the device
class Motion::Config < Motion::Base
  base "/api/motion/config"

  SETTING_MUTEX = Mutex.new

  # view the current configuration
  @[AC::Route::GET("/")]
  def index : Array(Setting)
    SETTING_MUTEX.synchronize { Setting.read_config[:motion] }
  end

  # add a new motion detection action
  @[AC::Route::POST("/", body: :motion, status_code: HTTP::Status::CREATED)]
  def create(motion : Motion::Setting) : Setting
    SETTING_MUTEX.synchronize do
      settings = Setting.read_config[:motion]
      settings << motion
      Setting.write_config(settings)
    end
    motion
  end

  # view the current configuration
  @[AC::Route::GET("/:id")]
  def show(
    @[AC::Param::Info(description: "the index of the motion configuration", example: "2")]
    id : Int32
  ) : Setting
    SETTING_MUTEX.synchronize { Setting.read_config[:motion][id] }
  end

  # replace the configuration at index id with new configuration
  @[AC::Route::PUT("/:id", body: :motion)]
  def update(
    @[AC::Param::Info(description: "the index of the motion configuration", example: "2")]
    id : Int32,
    motion : Motion::Setting
  ) : Setting
    SETTING_MUTEX.synchronize do
      settings = Setting.read_config[:motion]
      settings[id] = motion
      Setting.write_config(settings)
    end
    motion
  end

  # remove a motion detection configuration
  @[AC::Route::DELETE("/:id", status_code: HTTP::Status::ACCEPTED)]
  def destroy(
    @[AC::Param::Info(description: "the index of the motion configuration", example: "2")]
    id : Int32
  ) : Nil
    SETTING_MUTEX.synchronize do
      settings = Setting.read_config[:motion]
      settings.delete_at(id)
      Setting.write_config(settings)
    end
  end
end
