module Wescontrol
  # This router connects to all of the devices using the REQ/REP pattern 
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
