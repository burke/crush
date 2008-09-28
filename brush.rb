require 'readline'

PROMPT = "brush> "

def handle(cmd)
  prog_name = cmd.split(' ')[0]
  if not `which #{prog_name}`.strip.empty?
    # This exists in the path.
    cmd.gsub!(/#\{(.*?)\}/) do |match|
      match = match[2..-2]
      eval(match)
    end
    system(cmd)
  else
    # Not a valid binary in path.
    puts eval(cmd)
  end
end

loop do
  line = Readline::readline(PROMPT)
  Readline::HISTORY.push(line) rescue nil
  handle line
end

