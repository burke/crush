# Crush:    The Clockwork Ruby Shell
#
# Author:   Burke Libbey / Chromium 53
# License:  BSD
# Modified: <2008-09-28 20:12:35 CDT>

require 'readline'

class Array
  # This is almost certainly a bad idea, but it works nicely here.
  # Shells will typically expect lists to be space-separated, so we encourage that format.
  def to_s
    self.join(' ')
  end
  # Recall the default is .join('')
end

class Crush
  attr_accessor :prompt

  def initialize
    # Here we create a new empty binding to eval user input in
    @binding = lambda{|| binding }
    @prompt  = "crush> "
  end

  def evaluate(cmd)
    tokens = cmd.split(' ')
    command_name = tokens[0]

    # If this has been defined as a Crush override method...
    #if (meth = Crush.method(command_name) rescue nil)
    #  puts meth.call(tokens[1..-1])

    # If this program exists within the current PATH...
    if not `which #{command_name}`.strip.empty?
      cmd.gsub!(/#\{(.*?)\}/) do |match|
        match = match[2..-2]
        evaluate(match)
      end
      return `TERM='xterm-color' #{cmd}`

    # No match. Parse it as ruby and hope for the best.
    else
      return eval(cmd, @binding)
    end
  end

  def self.method_missing(name, *args)
    if not `which #{name}`.strip.empty?
      system("#{name} #{args.join(' ')}")
    else
      raise(NoMethodError, "undefined method '#{name}' for Crush")
    end
  end
end

if __FILE__ == $0
  crush = Crush.new
  loop do
    line = Readline::readline(crush.prompt)
    Readline::HISTORY.push(line) rescue nil
    puts crush.evaluate(line)
  end
end
