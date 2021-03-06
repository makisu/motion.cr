module Motion::Adapters
  # :nodoc:
  class Server < Base
    private getter periodic_timers : Array(String) = Array(String).new
    private getter broadcast_streams : Hash(String, Array(String)) = Hash(String, Array(String)).new
    private getter components : Hash(String, String) = Hash(String, String).new

    def get_component(topic : String) : Motion::Base
      weak_deserialize(components[topic]?.not_nil!)
    rescue error : NilAssertionError
      raise Motion::Exceptions::NoComponentConnectionError.new(topic)
    end

    def get_components(topics : Array(String)) : Array(Tuple(String, Motion::Base))
      topics.map_with_index do |topic, idx|
        {topics[idx], get_component(topic)}
      end
    end

    def set_component(topic : String, component : Motion::Base) : Bool
      !!(components[topic] = Motion.serializer.weak_serialize(component))
    end

    def destroy_component(topic : String) : Bool
      !!components.delete(topic)
    end

    def get_broadcast_streams(stream_topic : String) : Array(String)
      broadcast_streams[stream_topic]? || [] of String
    end

    def set_broadcast_streams(topic : String, component : Motion::Base) : Bool
      return true unless component.responds_to?(:broadcast_channel)
      channel = component.broadcast_channel

      broadcast_streams[channel] ||= [] of String
      broadcast_streams[channel] << topic

      true
    end

    def destroy_broadcast_stream(topic : String, component : Motion::Base) : Bool
      return true unless component.responds_to?(:broadcast_channel)

      channel = component.broadcast_channel
      !!broadcast_streams[channel].delete(topic)
    end

    def get_periodic_timers : Array(String)
      periodic_timers
    end

    def set_periodic_timers(topic : String, component : Motion::Base, &block) : Bool
      component.periodic_timers.each do |periodic_timer|
        name = periodic_timer[:name]

        periodic_timers.push(name)
        Motion.logger.info("Periodic Timer #{name} has been registered")
        spawn do
          while connected?(name) && periodic_timer_active?(name)
            Motion.action_timer.process_periodic_timer(name) do
              sleep periodic_timer[:interval]
              periodic_timer[:method].call

              block.call
            end
          end
        end
      end

      true
    end

    def destroy_periodic_timers(component : Motion::Base) : Bool
      component.periodic_timers.each do |timer|
        if name = timer[:name]
          periodic_timers.delete(name)
          Motion.logger.info("Periodic Timer #{name} has been disabled")
        end
      end

      true
    end
  end
end
