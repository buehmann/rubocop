# frozen_string_literal: true

module RuboCop
  module Cop
    module Lint
      # FIXME
      class AdjacentStringLiterals < Cop
        include MatchRange

        def on_dstr(node)
          return unless adjacent_string_literals?(node)

          add_offense(node, message: 'Adjacent string literals')

          node.children.drop(1).each do |child|
            if start_with_whitespace?(child)
              add_offense(child, message: 'Starts with whitespace')
            end
          end
        end

        private

        def adjacent_string_literals?(node)
          return if delimited_string?(node)

          node.children.all? { |c| delimited_string?(c) }
        end

        def delimited_string?(node)
          return unless node.str_type? || node.dstr_type?

          loc = node.loc
          %i[begin end].all? do |selector|
            loc.respond_to?(selector) && loc.public_send(selector)
          end
        end

        def start_with_whitespace?(node)
          if node.str_type?
            string_contents_range(node).source.start_with?(' ', "\t")
          elsif node.dstr_type?
            start_with_whitespace?(node.children.first)
          end
        end

        def string_contents_range(node)
          if delimited_string?(node)
            node.loc.begin.end.join(node.loc.end.begin)
          else
            node.loc.expression
          end
        end
      end

      # rubocop:disable all
      # rubocop:enable Lint/AdjacentStringLiterals
      def test
        "foo" "bar"

        "   foo" \
          "\t\s  bar#{foo}" '  foo'

        %q(foo) \
          "foo"

        "  foo\nbar"
      end
      # rubocop:enable all
    end
  end
end
