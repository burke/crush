# Crush:    The Clockwork Ruby Shell
#
# Author:   Burke Libbey / Chromium 53
# License:  BSD
# Modified: <2008-09-28 21:13:33 CDT>

require 'rubygems'
require 'readline'
require 'highline'

# It's convenient to be able to access this in random lambdas.
# May the coding gods have mercy on my soul.
$h = HighLine.new

class Array
  # This is almost certainly a bad idea, but it works nicely here.
  # Shells will typically expect lists to be space-separated, so we encourage that format.
  def to_s
    self.join(' ')
  end
  # Recall the default is .join('')
end

class Crush
  def initialize
    # Here we create a new empty binding to eval user input in
    @binding = lambda{ binding }
    @prompt  = lambda{ "#{$h.color(`pwd`.strip.split('/').last, :magenta)} #{$h.color('%', :green)} "}

    Signal.trap("INT")  { }
    Signal.trap("STOP") { } # This doesn't seem to work. Maybe it's a zsh thing.

  end

  def prompt
    @prompt.call
  end

  def evaluate(cmd, subexpr=nil)
    cmd.gsub!(/#\{(.*?)\}/) do |match|
      match = match[2..-2]
      evaluate(match, true)
    end

    tokens = cmd.split(' ')
    command_name = tokens[0]

    # If this has been defined as a Crush override method...
    #if (meth = Crush.method(command_name) rescue nil)
    #  puts meth.call(tokens[1..-1])

    # If this program exists within the current PATH...
    if not `which #{command_name}`.strip.empty?

      # I'd like to be able to toss everything around with %x{},
      # but it seems to force TERM=dumb, so we need to do top-level
      # calls with system(), and handle output *inside* this method.
      return subexpr ? `#{cmd}` : system( cmd )

    # No match. Parse it as ruby and hope for the best.
    else
      return subexpr ? eval(cmd, @binding) : (puts eval(cmd, @binding))
    end
  end

end

if __FILE__ == $0
  crush = Crush.new
  loop do
    line = Readline::readline(crush.prompt)
    begin
      Readline::HISTORY.push(line)
    rescue
      # As far as I can tell, this only errors when line = ^D, so quit.
      puts ""
      exit 0
    end
    begin
      crush.evaluate(line)
    rescue NameError
      puts "crush: invalid command: #{line.split(' ').first}"
    rescue
      puts "crush: unspecified error"
    end
  end
end
