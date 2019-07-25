# frozen_string_literal: true

module RuboCop
  module AST
    # Common functionality for primitive numeric nodes: `int`, `float`, ...
    module NumericNode
      include BasicLiteralNode

      SIGN_REGEX = /\A[+-]/.freeze

      # Checks whether this is literal has a sign.
      #
      # @example
      #
      #   +42
      #
      # @return [Boolean] whether this literal has a sign.
      def sign?
        source.match(SIGN_REGEX)
      end
    end
  end
end
