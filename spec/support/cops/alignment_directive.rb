# frozen_string_literal: true

module RuboCop
  module Cop
    module Test
      class AlignmentDirective < RuboCop::Cop::Cop
        MSG = 'Indent this node'

        def investigate(processed_source)
          processed_source.ast_with_comments.each do |node, comments|
            add_offense(node) if comments.find { |c| @column_delta = delta(c) }
          end
        end

        def autocorrect(node)
          AlignmentCorrector.correct(processed_source, node, @column_delta)
        end

        private

        def delta(comment)
          /\A#\s*(<<|>>)\s*(\d+)\s*\z/.match(comment.text) do |m|
            (m[1] == '<<' ? -1 : 1) * m[2].to_i
          end
        end
      end
    end
  end
end
