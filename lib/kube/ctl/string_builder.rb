# frozen_string_literal: true

# Monkey-patches for string_builder gem to support kubectl DSL patterns.

# Methods that are defined on Object/Kernel/Enumerable and shadow method_missing.
# These need explicit overrides so they work in the DSL.
SHADOWED_METHODS = %i[describe display freeze min max select sort format test clone p].freeze

class StringBuilder
  # Provide a safe, concise representation for REPL/debug output.
  def inspect
    command = begin
      to_s
    rescue StandardError
      '<unrenderable>'
    end

    parts = @buffer.respond_to?(:size) ? @buffer.size : 0
    %(#<#{self.class} command=#{command.inspect} parts=#{parts}>)
  end

  # Override call to handle kwargs: .(description: 'my frontend')
  # stores [{description: "my frontend"}] in the buffer.
  def call(token = nil, **kwargs)
    tap do
      if token
        @buffer << [token.to_s, []]
      elsif kwargs.any?
        @buffer << [kwargs]
      end
    end
  end

  SHADOWED_METHODS.each do |name|
    define_method(name) do |*args, **kwargs|
      tap do
        if kwargs.empty?
          @buffer << [name.to_s, args]
        else
          @buffer << [name.to_s, [*args, kwargs]]
        end
      end
    end
  end
end

class InnerStringBuilder
  # Override call to handle kwargs on InnerStringBuilder too.
  def call(token = nil, **kwargs)
    tap do
      if token
        @buffer << [token.to_s, []]
      elsif kwargs.any?
        @buffer << [kwargs]
      end
    end
  end

  # Override / and - operators to handle non-builder operands (e.g. integers, strings).
  # The gem's operators call other.each, which fails for plain values like `1`.
  InnerStringBuilder::OPERATOR_MAP.keys.each do |operator|
    define_method(operator) do |other|
      tap do
        @buffer << InnerStringBuilder::OPERATOR_MAP[operator]
        if other.respond_to?(:each) && !other.is_a?(String) && !other.is_a?(Numeric)
          other.each { |token| @buffer << token }
        else
          @buffer << [other.to_s, []]
        end
      end
    end
  end

  SHADOWED_METHODS.each do |name|
    define_method(name) do |*args, **kwargs|
      tap do
        if kwargs.empty?
          @buffer << [name.to_s, args]
        else
          @buffer << [name.to_s, [*args, kwargs]]
        end
      end
    end
  end
end

class ScopedStringBuilder
  SHADOWED_METHODS.each do |name|
    define_method(name) do |*args, **kwargs|
      InnerStringBuilder.new.send(name, *args, **kwargs)
    end
  end
end
