lines = File.readlines("/home/nathan/kube/ctl/lib/kube/ctl/string_builder.rb")

# Find the start of the bottom if __FILE__ == $0 block (line index 94 = line 95)
block_start = 94  # 0-indexed

# Build output for the replacement test block
output = []
output << "test do"
output << "  require_relative \"../../../setup\""
output << ""
output << "  sb = ->(&block) { Kube.ctl(&block) }"
output << ""

# Parse tests from lines
i = block_start
in_test = false
test_name = nil
test_lines = []
skipped_comments = []

while i < lines.size
  line = lines[i]
  stripped = line.strip

  # Skip the boilerplate
  if stripped == "if __FILE__ == $0" ||
     stripped == 'require "bundler/setup"' ||
     stripped == 'require "minitest/autorun"' ||
     stripped == 'require "kube/ctl"' ||
     stripped.start_with?("module Kube") ||
     stripped.start_with?("module Ctl") ||
     stripped.start_with?("module VCluster") ||
     stripped == "def self.run(args) = args" ||
     (stripped == "end" && !in_test) ||
     stripped.start_with?("class CommandTreeTest") ||
     stripped.start_with?("def sb(") ||
     stripped.start_with?("Kube.ctl(") ||
     stripped.start_with?("def assert_buffer") ||
     stripped.start_with?("assert_equal expected, result.to_a") ||
     stripped.start_with?("def assert_string") ||
     stripped.start_with?("assert_equal expected, result.to_s") ||
     stripped.empty?
    i += 1
    next
  end

  # Capture skipped-test comments
  if stripped.start_with?("# Skipped:")
    skipped_comments << line
    i += 1
    next
  end
  if stripped.start_with?("# def test_")
    skipped_comments << line
    i += 1
    next
  end
  if stripped.start_with?("#") && !skipped_comments.empty?
    skipped_comments << line
    i += 1
    next
  end

  # Flush any skipped comments
  unless skipped_comments.empty?
    skipped_comments.each { |c| output << "  #{c.rstrip}" }
    output << ""
    skipped_comments = []
  end

  # Match test method definition
  if stripped =~ /^def (test_\w+)/
    test_name = $1.sub(/^test_/, "")
    test_lines = []
    in_test = true
    i += 1
    next
  end

  if in_test
    if stripped == "end"
      # Emit the test
      result_line = test_lines.find { |l| l.strip.start_with?("result =") }
      string_line = test_lines.find { |l| l.strip.start_with?("assert_string(") }

      if result_line && string_line
        expr = result_line.strip.sub(/^result = /, "")
        # Extract expected string - handle escaped quotes
        if string_line.strip =~ /assert_string\(result,\s*"(.*)"\)\s*$/
          expected = $1
          output << "  it \"#{test_name}\" do"
          output << "    #{expr}.to_s.should == \"#{expected}\""
          output << "  end"
          output << ""
        end
      end

      in_test = false
      test_lines = []
    else
      test_lines << line
    end
    i += 1
    next
  end

  i += 1
end

# Flush trailing skipped comments
unless skipped_comments.empty?
  skipped_comments.each { |c| output << "  #{c.rstrip}" }
  output << ""
  skipped_comments = []
end

output << "end"

# Now replace from block_start to end of file
new_content = lines[0...block_start].map(&:rstrip).join("\n") + "\n" + output.join("\n") + "\n"
File.write("/home/nathan/kube/ctl/lib/kube/ctl/string_builder.rb", new_content)
puts "Done. Wrote #{output.size} output lines"
