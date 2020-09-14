module Motion
  class ConnectionManager
    property component_connections : Hash(String, Motion::ComponentConnection?) = Hash(String, Motion::ComponentConnection?).new
    property fibers : Hash(String, Fiber) = Hash(String, Fiber).new
    getter channel : Motion::Channel

    def initialize(@channel : Motion::Channel); end

    def create(message : Motion::Message)
      set_component(message.topic, message.state)
    end

    def destroy(message : Motion::Message)
      topic = message.topic

      self.get(topic).close do |component|
        component.periodic_timers.each do |timer|
          if name = timer[:name]
            fibers.delete(name)
            logger.info("Periodic Timer #{name} has been disabled")
          end
        end
        component_connections.delete(topic)
      end
    end

    def process_motion(message : Motion::Message)
      self.get(message.topic).process_motion(message.name, message.event)
    end

    def synchronize(topic : String, proc)
      self.get(topic).if_render_required(proc)
    end

    def process_periodic_timer(topic : String)
      self.get(topic).periodic_timers.each do |timer|
        name = timer[:name].to_s
        self.fibers[name] = spawn do
          while connected?(topic) && periodic_timer_active?(name)
            proc = ->do
              interval = timer[:interval]
              sleep interval if interval.is_a?(Time::Span)

              method = timer[:method]
              method.call if method.is_a?(Proc(Nil))
            end

            get(topic).process_periodic_timer(proc, name.to_s)
            channel.synchronize(topic: topic, broadcast: true)
          end
        end
      end
    end

    def get(topic : String) : Motion::ComponentConnection
      self.component_connections[topic]?.not_nil!
    rescue error : NilAssertionError
      raise Motion::Exceptions::NoComponentConnectionError.new(topic)
    end

    private def set_component(topic : String, state : String)
      self.component_connections[topic] = connect_component(state)
    end

    private def connect_component(state)
      ComponentConnection.from_state(state)
    rescue e : Exception
      # reject
      handle_error(e, "connecting a component")
    end

    private def connected?(topic)
      !self.get(topic).nil?
    end

    # TODO: Some way to allow users to invoke
    # a method to stop a particular timer
    private def periodic_timer_active?(name)
      true
    end

    private def handle_error(error, context)
      logger.error("An error occurred while #{context} & #{error}")
    end

    private def logger
      Motion.logger
    end
  end
end