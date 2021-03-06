require "../spec_helper"

[:server, :redis].each do |adapter|
  describe Motion::ConnectionManager do
    describe "with #{adapter} adapter" do
      before_each do
        Redis.new(url: Motion.config.redis_url).flushdb

        Motion.configure do |config|
          config.adapter = adapter
        end
      end

      after_each do
        Redis.new(url: Motion.config.redis_url).flushdb
        Motion.reset_config
      end

      pending "can process a motion"

      it "can create components" do
        component_connection = Motion::ConnectionManager.new(Motion::Channel.new)
        message = Motion::Message.new(MESSAGE_JOIN)
        component_connection.create(message).should be_true
      end

      pending "can destroy components"

      it "can process multiple broadcast streams at once" do
        component_connection = Motion::ConnectionManager.new(Motion::Channel.new)
        component = BroadcastComponent.new

        ["motion:87092", "motion:81292", "motion:87834"].each do |topic|
          component_connection.adapter.set_component(topic, component)
          component_connection.adapter.set_broadcast_streams(topic, component)
        end

        component_connection.process_model_stream(component.broadcast_channel).should be_true
      end
    end
  end
end
