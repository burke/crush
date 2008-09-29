#!/usr/bin/env ruby

# Crush:    The Clockwork Ruby Shell
#
# Author:   Burke Libbey / Chromium 53
# License:  BSD
# Modified: <2008-09-28 23:34:36 CDT>

begin
  require 'rubygems'
rescue LoadError
end
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
    # Here we create a new empty binding to eval user input in.
    # I think this works.
    @binding = lambda{ binding }
    @prompt  = lambda{ "#{$h.color(Dir.pwd.split('/').last,:magenta)} #{$h.color('%',:green)} "}
    @aliases = { }

    Signal.trap("INT")  { }
    Signal.trap("STOP") { } # This doesn't seem to work

  end

  def prompt
    @prompt.call
  end

  def synonym(from, to)
    @aliases.merge!({ from => to })
  end

  def evaluate(cmd, subexpr=nil)
    cmd.gsub!(/#\{(.*?)\}/) do |match|
      match = match[2..-2]
      evaluate(match, true)
    end

    tokens = cmd.split(' ')
    command_name = tokens[0]

    # If this program exists within the current PATH...
    if not IO.popen('-') {|f| f ? f.read : exec('which',command_name)}.strip.empty?

      # I'd like to be able to toss everything around with %x{},
      # but afaik I can only get the "fancy" output by writing directly to $stdout.

      if @aliases[command_name]
        cmd = "#{@aliases[command_name]} #{tokens[1..-1]}"
      end

      if subexpr
        return `#{cmd}`
      else
        # This is hackish, but I need to get the cwd back from the subprocess.
        system("#{cmd};pwd>/tmp/crush_cwd")
        Dir.chdir(File.read('/tmp/crush_cwd').strip)
      end

    # No match. Parse it as ruby and hope for the best.
    else
      return subexpr ? eval(cmd, @binding) : (puts eval(cmd, @binding))
    end
  end

end

if __FILE__ == $0
  crush = Crush.new
  crush.instance_eval(File.read("#{ENV['HOME']}/.crushrc")) rescue nil
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
