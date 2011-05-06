module Watchman
  class Tree
  def initialize
    end

    def or(other)

    end

    def and(other)

    end

    def transform_query(f)
      new_query = new Query
      new_query.check = f(@check)
      new_query
    end

    def negate
      new_query = self
      new_query.check = nil
    end
  end

  class Rule
    def initialize(env)
      @format = Regexp.compile()

      @pred = new Query
      @actions = []

      @last_checked = Time.new
      @frequency = 100
    end

    def computed(behavior)

    end

    # format: "when _ do ; ; ; "
    def parse (txt)
      raise "Incorrect format" unless txt.length == 4
      _, condition, _, action = txt.split
    end

    def to_s
    end
  end
end
