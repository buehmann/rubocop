# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::EmptyComment, :config do
  subject(:cop) { described_class.new(config) }

  let(:cop_config) do
    { 'AllowBorderComment' => true, 'AllowMarginComment' => true }
  end

  it 'registers an offense when using single line empty comment' do
    expect_offense(<<~RUBY)
      #
      ^ Source code comment is empty.
    RUBY
  end

  it 'registers an offense when using multiline empty comments' do
    expect_offense(<<~RUBY)
      #
      ^ Source code comment is empty.
      #
      ^ Source code comment is empty.
    RUBY
  end

  it 'registers an offense when using an empty comment next to code' do
    expect_offense(<<~RUBY)
      def foo #
              ^ Source code comment is empty.
        something
      end
    RUBY
  end

  it 'does not register an offense when using comment text' do
    expect_no_offenses(<<~RUBY)
      # Description of `Foo` class.
      class Foo
        # Description of `hello` method.
        def hello
        end
      end
    RUBY
  end

  it 'does not register an offense when using comment text with ' \
     'leading and trailing blank lines' do
    expect_no_offenses(<<~RUBY)
      #
      # Description of `Foo` class.
      #
      class Foo
        #
        # Description of `hello` method.
        #
        def hello
        end
      end
    RUBY
  end

  context 'allow border comment (default)' do
    it 'does not register an offense when using border comment' do
      expect_no_offenses(<<~RUBY)
        #################################
      RUBY
    end
  end

  context 'disallow border comment' do
    let(:cop_config) { { 'AllowBorderComment' => false } }

    it 'registers an offense when using single line empty comment' do
      expect_offense(<<~RUBY)
        #
        ^ Source code comment is empty.
      RUBY
    end

    it 'registers an offense when using border comment' do
      expect_offense(<<~RUBY)
        #################################
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Source code comment is empty.
      RUBY
    end
  end

  context 'allow margin comment (default)' do
    it 'does not register an offense when using margin comment' do
      expect_no_offenses(<<~RUBY)
        #
        # Description of `hello` method.
        #
        def hello
        end
      RUBY
    end
  end

  context 'disallow margin comment' do
    let(:cop_config) { { 'AllowMarginComment' => false } }

    it 'registers an offense when using margin comment' do
      expect_offense(<<~RUBY)
        #
        ^ Source code comment is empty.
        # Description of `hello` method.
        #
        ^ Source code comment is empty.
        def hello
        end
      RUBY
    end
  end

  it 'autocorrects empty comment' do
    new_source = autocorrect_source(<<~RUBY)
      #
      class Foo
        #
        def hello
        end
      end
    RUBY

    expect(new_source).to eq <<~RUBY
      class Foo
        def hello
        end
      end
    RUBY
  end

  it 'autocorrects an empty comment next to code' do
    new_source = autocorrect_source(<<~RUBY)
      def foo #
        something
      end
    RUBY

    expect(new_source).to eq(<<~RUBY)
      def foo
        something
      end
    RUBY
  end

  it 'autocorrects an empty comment next to heredoc' do
    new_source = autocorrect_source(<<~RUBY)
      puts <<DOC #
      DOC
    RUBY

    expect(new_source).to eq(<<~RUBY)
      puts <<DOC
      DOC
    RUBY
  end

  it 'autocorrects an empty comment without space next to code' do
    new_source = autocorrect_source(<<~RUBY)
      def foo#
        something
      end
    RUBY

    expect(new_source).to eq(<<~RUBY)
      def foo
        something
      end
    RUBY
  end

  it 'autocorrects multiple empty comments next to code' do
    new_source = autocorrect_source(<<~RUBY)
      def foo #
        something #
      end
    RUBY

    expect(new_source).to eq(<<~RUBY)
      def foo
        something
      end
    RUBY
  end

  it 'autocorrects multiple aligned empty comments next to code' do
    new_source = autocorrect_source(<<~RUBY)
      def foo     #
        something #
      end
    RUBY

    expect(new_source).to eq(<<~RUBY)
      def foo
        something
      end
    RUBY
  end
end
