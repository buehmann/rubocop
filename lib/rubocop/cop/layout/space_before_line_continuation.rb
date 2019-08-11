# frozen_string_literal: true

module RuboCop
  module Cop
    module Layout
      # Checks that the backslash of a line continuation (outside of string
      # literals) is separated from preceding text by exactly one space.
      #
      # @example
      #   # bad
      #   'a'\
      #   'b'  \
      #   'c'
      #
      #   # good
      #   'a' \
      #   'b' \
      #   'c'
      class SpaceBeforeLineContinuation < Cop
        include MatchRange

        MSG_EXTRA   = 'Extra space before line continuation'
        MSG_MISSING = 'Missing space before line continuation'

        def investigate(processed_source)
          before_line_continuation(processed_source) do |space|
            # Do not worry about indentation of backslashes in otherwise empty
            # lines. TODO: This should be an indentation cop's responsibility.
            next if space.column.zero?

            if space.empty?
              add_offense(space, location: space.adjust(end_pos: +1),
                                 message: MSG_MISSING)
            elsif space.size > 1
              extra_space = space.adjust(end_pos: -1)
              add_offense(extra_space, location: extra_space,
                                       message: MSG_EXTRA)
            end
          end
        end

        def autocorrect(space)
          lambda do |corrector|
            if space.empty?
              corrector.insert_after(space, ' ')
            else
              corrector.remove(space)
            end
          end
        end

        private

        def before_line_continuation(processed_source)
          sorted_tokens(processed_source).each_cons(2) do |token1, token2|
            next if token1.line == token2.line

            between = token1.pos.end.join(token2.pos.begin)
            each_match_range(between, /([^\S\n]*)\\\n/) { |space| yield space }
          end
        end

        def sorted_tokens(processed_source)
          processed_source.tokens.sort_by(&:pos)
        end
      end
    end
  end
end
