module Motion::Adapters
  # :nodoc:
  abstract class Base
    abstract def get_component(topic : String) : Motion::Base
    abstract def get_components(topics : Array(String)) : Array(Tuple(String, Motion::Base))
    abstract def set_component(topic : String, component : Motion::Base) : Bool
    abstract def destroy_component(topic : String) : Bool

    abstract def get_broadcast_streams(stream_topic : String) : Array(String)
    abstract def set_broadcast_streams(topic : String, component : Motion::Base) : Bool
    abstract def destroy_broadcast_stream(topic : String, component : Motion::Base) : Bool

    abstract def get_periodic_timers : Array(String)
    abstract def set_periodic_timers(topic : String, component : Motion::Base, &block) : Bool
    abstract def destroy_periodic_timers(component : Motion::Base) : Bool

    def weak_deserialize(component : String) : Motion::Base
      Motion.serializer.weak_deserialize(component)
    end

    private def connected?(name : String) : Bool
      get_periodic_timers.includes?(name)
    end

    # TODO: Some way to allow users to invoke
    # a method to stop a particular timer
    private def periodic_timer_active?(name) : Bool
      true
    end
  end
end
