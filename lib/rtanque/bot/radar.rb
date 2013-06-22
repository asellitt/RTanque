module RTanque
  class Bot
    class Radar
      include Enumerable
      include Movable
      extend NormalizedAttr
      VISION_RANGE = Configuration.radar.vision
      attr_normalized(:heading, Heading::FULL_RANGE, Configuration.radar.turn_step)

      # A Reflection is the information obtained for a bot detected by {RTanque::Bot::Radar}
      #
      # @attr_reader [RTanque::Heading] heading
      # @attr_reader [Float] distance
      # @attr_reader [String] name
      Reflection = Struct.new(:heading, :distance, :name, :type, :speed, :id) do
        def self.new_from_points(from_position, to_position, &tap)
          self.new(from_position.heading(to_position), from_position.distance(to_position)).tap(&tap)
        end
      end

      def initialize(bot, heading)
        @bot = bot
        @heading = heading
        @reflections = []
      end

      def position
        @bot.position
      end

      def each(&block)
        @reflections.each(&block)
      end

      def empty?
        self.count == 0
      end

      def scan(bots, shells = [])
        @reflections.clear
        bots.each do |other_bot|
          if self.can_detect?(other_bot)
            @reflections << Reflection.new_from_points(self.position, other_bot.position) do |reflection|
             reflection.name = other_bot.name
             reflection.type = :bot
            end
          end
        end
        shells.each do |shell|
          if self.can_detect?(shell)
            @reflections << Reflection.new_from_points(self.position, shell.position) do |reflection|
             reflection.name = shell.bot.name
             reflection.type = :shell
             reflection.speed = shell.speed
             reflection.id = shell.identifier
            end
          end
        end
        self
      end

      def can_detect?(other_object)
        VISION_RANGE.include?(Heading.delta_between_points(self.position, self.heading, other_object.position))
      end
    end
  end
end
