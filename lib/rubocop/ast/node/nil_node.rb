# frozen_string_literal: true

module RuboCop
  module AST
    # A node extension for `nil` nodes. This will be used in place of a plain
    # node when the builder constructs the AST, making its methods available to
    # all `nil` nodes within RuboCop.
    class NilNode < Node
      include BasicLiteralNode

      def value
        nil
      end
    end
  end
end
