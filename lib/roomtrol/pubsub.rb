module Wescontrol
  # In 0mq pubsub is limited to 1 publish -> many subscribers.
  # However, we have many publishers (each device) and several
  # subscribers (websocket, http, eventmonitor, etc.). This class sets
  # up a 0mq service that acts as a simple broker (roughly occupying
  # the same place as RabbitMQ in our old architecture but about a
  # million times simpler). It binds on two sockets: a PUB and a
  # PULL. Subscribers connect to the former while publishers connect
  # to the latter. The publishers send multipart messages on the pipe
  # with the topic as the first part and the body as the second. These
  # then get passed on to subscribers if their topic bindings match
  # the topic of the message.
  class PubSubRouter
    # Creates a new PubSubROuter.
    #
    # @param pub The pub port is a PULL socket that publishers push
    #   data to.
    # @param sub The sub port is a PUB socket that subcribers
    #   subscribe to
    def initialize pub, sub
      @pub_port = pub
      @sub_port = sub
    end

    def run ctx = nil
      ctx ||= EM::ZeroMQ::Context.new(1)
      EM.run {
        pub = ctx.bind(ZMQ::PUB, @sub_port)

        pull_handler = ZMQClient.new
        pull_handler.subscribe_multi{|socket, messages|
          pub.send_msg(*messages)
        }
        ctx.bind(ZMQ::PULL, @pub_port, pull_handler)
      }
    end
  end
end
