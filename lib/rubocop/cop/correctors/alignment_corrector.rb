# frozen_string_literal: true

module RuboCop
  module Cop
    # This class does auto-correction of nodes that should just be moved to
    # the left or to the right, amount being determined by the instance
    # variable column_delta.
    class AlignmentCorrector
      include RangeHelp
      include Alignment

      class << self
        def correct(processed_source, node, column_delta)
          new(processed_source).correct(node, column_delta)
        end

        def align_end(processed_source, node, align_to)
          new(processed_source).align_end(node, align_to)
        end
      end

      attr_reader :processed_source

      def initialize(processed_source)
        @processed_source = processed_source
      end

      def correct(node, column_delta)
        return unless node

        expr = node.respond_to?(:loc) ? node.loc.expression : node

        taboo_ranges = taboo_ranges(node)

        lambda do |corrector|
          each_line(expr) do |line_begin_pos|
            autocorrect_line(corrector, line_begin_pos, column_delta,
                             taboo_ranges)
          end
        end
      end

      def align_end(node, align_to)
        whitespace = whitespace_range(node)
        return false unless whitespace.source.strip.empty?

        column = alignment_column(align_to)
        ->(corrector) { corrector.replace(whitespace, ' ' * column) }
      end

      private

      def autocorrect_line(corrector, line_begin_pos, column_delta,
                           taboo_ranges)
        range = calculate_range(line_begin_pos, column_delta)
        # We must not change indentation of heredoc strings or inside other
        # string literals
        return if taboo_ranges.any? { |t| within?(range, t) }

        if column_delta.positive?
          unless range.resize(1).source == "\n"
            corrector.insert_before(range, ' ' * column_delta)
          end
        elsif range.source =~ /\A[ \t]+\z/
          remove(range, corrector)
        end
      end

      def taboo_ranges(node)
        inside_string_ranges(node) + block_comment_ranges
      end

      def inside_string_ranges(node)
        return [] unless node.is_a?(Parser::AST::Node)

        node.each_node(:str, :dstr, :xstr).map { |n| inside_string_range(n) }
            .compact
      end

      def inside_string_range(node)
        if node.heredoc?
          node.loc.heredoc_body.join(node.loc.heredoc_end)
        else
          inside_regular_string_range(node)
        end
      end

      def inside_regular_string_range(node)
        loc = node.location
        return unless loc.respond_to?(:begin) && loc.respond_to?(:end)
        return if loc.begin.nil? || loc.end.nil?

        loc.begin.end.join(loc.end.begin)
      end

      def block_comment_ranges
        processed_source.comments.select(&:document?).map do |c|
          range = c.loc.expression
          if range.source.end_with?("\n")
            range.adjust(end_pos: -1)
          else
            range
          end
        end
      end

      def calculate_range(line_begin_pos, column_delta)
        if column_delta.positive?
          return range_between(line_begin_pos, line_begin_pos)
        end

        starts_with_space =
          processed_source.buffer.source[line_begin_pos].start_with?(' ')

        if starts_with_space
          range_between(line_begin_pos, line_begin_pos + column_delta.abs)
        else
          range_between(line_begin_pos - column_delta.abs, line_begin_pos)
        end
      end

      def remove(range, corrector)
        original_stderr = $stderr
        $stderr = StringIO.new # Avoid error messages on console
        corrector.remove(range)
      rescue RuntimeError
        range = range_between(range.begin_pos + 1, range.end_pos + 1)
        retry if range.source =~ /^ +$/
      ensure
        $stderr = original_stderr
      end

      def each_line(expr)
        line_begin_pos = expr.begin_pos
        expr.source.each_line do |line|
          yield line_begin_pos
          line_begin_pos += line.length
        end
      end

      def whitespace_range(node)
        begin_pos = node.loc.end.begin_pos

        range_between(begin_pos - node.loc.end.column, begin_pos)
      end

      def alignment_column(align_to)
        if !align_to
          0
        elsif align_to.respond_to?(:loc)
          align_to.source_range.column
        else
          align_to.column
        end
      end
    end
  end
end
