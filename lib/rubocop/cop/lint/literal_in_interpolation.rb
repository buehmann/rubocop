# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # This cop checks for interpolated literals.
      #
      # @example
      #
      #   # bad
      #
      #   "result is #{10}"
      #
      # @example
      #
      #   # good
      #
      #   "result is 10"
      class LiteralInInterpolation < Cop
        include Interpolation
        include RangeHelp
        include PercentLiteral

        MSG = 'Literal interpolation detected.'
        COMPOSITE = %i[array hash pair irange erange].freeze

        def on_interpolation(begin_node)
          final_node = begin_node.children.last
          return unless final_node
          return if special_keyword?(final_node)
          return unless prints_as_self?(final_node)

          add_offense(final_node)
        end

        def autocorrect(node)
          return if node.dstr_type? # nested, fixed in next iteration

          value = autocorrected_value(node)
          ->(corrector) { corrector.replace(node.parent.source_range, value) }
        end

        private

        def special_keyword?(node)
          # handle strings like __FILE__
          (node.str_type? && !node.loc.respond_to?(:begin)) ||
            node.source_range.is?('__LINE__')
        end

        def autocorrected_value(node)
          escape(value(node).to_s)
        end

        def escape(string)
          string.gsub('\\') { '\\\\' }.gsub('"', '\"')
        end

        # This range is used instead of Ruby's builtin one because the latter
        # varies across target versions (support for beginless and endless
        # ranges).
        class Range
          def initialize(from, to, inclusive: true)
            @from = from
            @to = to
            @inclusive = inclusive
          end

          def to_s
            dots = @inclusive ? '..' : '...'
            "#{@from}#{dots}#{@to}"
          end
        end

        def value(node)
          case node.type
          when :array, :pair
            child_values(node)
          when :hash
            Hash[child_values(node)]
          when :irange, :erange
            Range.new(*child_values(node), inclusive: node.irange_type?)
          else
            node.value
          end
        end

        def child_values(node)
          node.children.map { |c| value(c) }
        end

        # Does node print its own source when converted to a string?
        def prints_as_self?(node)
          node.basic_literal? ||
            (COMPOSITE.include?(node.type) &&
              node.children.all? { |child| prints_as_self?(child) })
        end
      end
    end
  end
end
