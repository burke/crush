require 'readline'

PROMPT = "brush> "

class Brush
  @@binding = binding
  def self.binding; @@binding; end

  def self.method_missing(name, *args)
    if not `which #{name}`.strip.empty?
      system("#{name} #{args.join(' ')}")
    else
      raise(NoMethodError, "undefined method '#{name}' for Brush")
    end
  end

end

def handle(cmd)
  tokens = cmd.split(' ')
  command_name = tokens[0]

  # If this has been defined as a Brush method...
  if (meth = Brush.method(command_name) rescue nil)
    puts meth.call(tokens[1..-1])

  # If this program exists within the current PATH...
  elsif not `which #{command_name}`.strip.empty?
    # This exists in the path.
    cmd.gsub!(/#\{(.*?)\}/) do |match|
      match = match[2..-2]
      eval(match, Brush.binding)
    end
    system("#{cmd}")

  # No match. Parse it as ruby and hope for the best.
  else
    puts eval(cmd, Brush.binding)
  end
end

loop do
  line = Readline::readline(PROMPT)
  Readline::HISTORY.push(line) rescue nil
  handle line
end

