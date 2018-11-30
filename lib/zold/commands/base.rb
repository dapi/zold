require 'zold'
module Zold
  module Command
    class Base
      include Virtus.model

      attribute :logger, Logger, default: -> { Universe.logger }

      def self.command_line_options
        # TODO work with sold and yield
      end

      def run(*args)
        # TODO parse options
        perform options
      end

      private

      attr_reader :logger
    end
  end
end
