require 'robot'

class Numeric
   TO_RAD = Math::PI / 180.0
   TO_DEG = 180.0 / Math::PI
   def to_rad
     self * TO_RAD
   end
   def to_deg
     self * TO_DEG
   end
end

class Battlefield
   attr_reader :width
   attr_reader :height
   attr_reader :robots
   attr_reader :teams
   attr_reader :bullets
   attr_reader :explosions
   attr_reader :time
   attr_reader :seed
   attr_reader :timeout  # how many ticks the match can go before ending.
   attr_reader :game_over

  def initialize width, height, timeout, seed
    @width, @height = width, height
    @seed = seed
    @time = 0
    @robots = []
    @teams = Hash.new{|h,k| h[k] = [] }
    @bullets = []
    @explosions = []
    @timeout = timeout
    @game_over = false
    srand @seed
  end

  def << object
    case object
    when RobotRunner
      @robots << object
      @teams[object.team] << object
    when Bullet
      @bullets << object
    when Explosion
      @explosions << object
    end
  end

  def tick
    explosions.delete_if{|explosion| explosion.dead}
    explosions.each{|explosion| explosion.tick}

    bullets.delete_if{|bullet| bullet.dead}
    bullets.each{|bullet| bullet.tick}

    robots.each do |robot|
      begin
        robot.send :internal_tick unless robot.dead
      rescue Exception => bang
        puts "#{robot} made an exception:"
        puts "#{bang.class}: #{bang}", bang.backtrace
        robot.instance_eval{@energy = -1}
      end
    end

    @time += 1
    live_robots = robots.find_all{|robot| !robot.dead}
    @game_over = (  (@time >= timeout) or # timeout reached
                    (live_robots.length == 0) or # no robots alive, draw game
                    (live_robots.all?{|r| r.team == live_robots.first.team})) # all other teams are dead
    not @game_over
  end

  def state
    {:explosions => explosions.map{|e| e.state},
     :bullets    => bullets.map{|b| b.state},
     :robots     => robots.map{|r| r.state}}
  end

end


class Explosion
  attr_accessor :x
  attr_accessor :y
  attr_accessor :t
  attr_accessor :dead

  def initialize bf, x, y
    @x, @y, @t = x, y, 0
    @battlefield, dead = bf, false
  end

  def state
    {:x=>x, :y=>y, :t=>t}
  end

  def tick
    @t += 1
    @dead ||= t > 15
  end
end

class Bullet
  attr_accessor :x
  attr_accessor :y
  attr_accessor :heading
  attr_accessor :speed
  attr_accessor :energy
  attr_accessor :dead
  attr_accessor :origin

  def initialize bf, x, y, heading, speed, energy, origin
    @x, @y, @heading, @origin = x, y, heading, origin
    @speed, @energy = speed, energy
    @battlefield, dead = bf, false
  end

  def state
    {:x=>x, :y=>y, :energy=>energy}
  end

  def tick
    return if @dead
    @x += Math::cos(@heading.to_rad) * @speed
    @y -= Math::sin(@heading.to_rad) * @speed

    @dead ||= (@x < 0) || (@x >= @battlefield.width)
    @dead ||= (@y < 0) || (@y >= @battlefield.height)

    @battlefield.robots.each do |other|
      if (other != origin) && (Math.hypot(@y - other.y, other.x - @x) < 40) && (!other.dead)
        explosion = Explosion.new(@battlefield, other.x, other.y)
        @battlefield << explosion
        damage = other.hit(self)
        origin.damage_given += damage
        origin.kills += 1 if other.dead
        @dead = true
      end
    end
  end
end

##############################################
# arena
##############################################

def usage
  puts "usage: rrobots.rb [resolution] [#match] [-nogui] [-speed=<N>] [-timeout=<N>] [-teams=<N>] <FirstRobotClassName[.rb]> <SecondRobotClassName[.rb]> <...>"
  puts "\t[resolution] (optional) should be of the form 640x480 or 800*600. default is 800x800"
  puts "\t[match] (optional) to replay a match, put the match# here, including the #sign.  "
  puts "\t[-nogui] (optional) run the match without the gui, for highest possible speed.(ignores speed value if present)"
  puts "\t[-speed=<N>] (optional, defaults to 1) updates GUI after every N ticks.  The higher the N, the faster the match will play."
  puts "\t[-timeout=<N>] (optional, default 50000) number of ticks a match will last at most."
  puts "\t[-teams=<N>] (optional) split robots into N teams. Match ends when only one team has robots left."
  puts "\tthe names of the rb files have to match the class names of the robots"
  puts "\t(up to 8 robots)"
  puts "\te.g. 'ruby rrobots.rb SittingDuck NervousDuck'"
  puts "\t or 'ruby rrobots.rb 600x600 #1234567890 SittingDuck NervousDuck'"
  exit
end

def run_out_of_gui(battlefield)
  $stderr.puts 'match ends if only 1 bot/team left or dots get here-->|'

  until battlefield.game_over
    battlefield.tick
    $stderr.print "." if battlefield.time % (battlefield.timeout / 54).to_i == 0
  end
  print_outcome(battlefield)
  exit 0
end

def run_in_gui(battlefield, xres, yres, speed_multiplier)
  require 'tkarena'
  arena = TkArena.new(battlefield, xres, yres, speed_multiplier)
  game_over_counter = battlefield.teams.all?{|k,t| t.size < 2} ? 250 : 500
  outcome_printed = false
  arena.on_game_over{|battlefield|
    unless outcome_printed
      print_outcome(battlefield)
      outcome_printed = true
    end
    exit 0 if game_over_counter < 0
    game_over_counter -= 1
  }
  arena.run
end

def print_outcome(battlefield)
  winners = battlefield.robots.find_all{|robot| !robot.dead}
  puts
  if battlefield.robots.size > battlefield.teams.size
    teams = battlefield.teams.find_all{|name,team| !team.all?{|robot| robot.dead} }
    puts "winner_is:     { #{
      teams.map do |name,team|
        "Team #{name}: [#{team.join(', ')}]"
      end.join(', ')
    } }"
    puts "winner_energy: { #{
      teams.map do |name,team|
        "Team #{name}: [#{team.map do |w| ('%.1f' % w.energy) end.join(', ')}]"
      end.join(', ')
    } }"
  else
    puts "winner_is:     [#{winners.map{|w|w.name}.join(', ')}]"
    puts "winner_energy: [#{winners.map{|w|'%.1f' % w.energy}.join(', ')}]"
  end
  puts "elapsed_ticks: #{battlefield.time}"
  puts "seed :         #{battlefield.seed}"
  puts
  puts "robots :"
  battlefield.robots.each do |robot|
    puts "  #{robot.name}:"
    puts "    damage_given: #{'%.1f' % robot.damage_given}"
    puts "    damage_taken: #{'%.1f' % (100 - robot.energy)}"
    puts "    kills:        #{robot.kills}"
  end
end

$stdout.sync = true

# look for resolution arg
xres, yres = 800, 800
ARGV.grep(/^(\d+)[x\*](\d+$)/) do |item|
  xres, yres = $1.to_i, $2.to_i
  ARGV.delete(item)
end

# look for match arg
seed = Time.now.to_i + Process.pid
ARGV.grep(/^#(\d+)/) do |item|
  seed = $1.to_i
  ARGV.delete(item)
end

#look for mode arg
mode = :run_in_gui
ARGV.grep( /^(-nogui)/ )do |item|
  mode = :run_out_of_gui
  ARGV.delete(item)
end

#look for speed multiplier arg
speed_multiplier = 1
ARGV.grep( /^-speed=(\d\d?)/ )do |item|
  x = $1.to_i
  speed_multiplier = x if x > 0 && x < 100
  ARGV.delete(item)
end

#look for timeout arg
timeout = 50000
ARGV.grep( /^-timeout=(\d+)/ )do |item|
  timeout = $1.to_i
  ARGV.delete(item)
end

#look for teams arg
team_count = 8
ARGV.grep( /^-teams=(\d)/ )do |item|
  x = $1.to_i
  team_count = x if x > 0 && x < 8
  ARGV.delete(item)
end
teams = Array.new([team_count, ARGV.size].min){ [] }

usage if ARGV.size > 8 || ARGV.empty?

battlefield = Battlefield.new xres*2, yres*2, timeout, seed

c = 0
team_divider = (ARGV.size / teams.size.to_f).ceil
ARGV.map! do |robot|
  begin
    begin
      require robot.downcase
    rescue LoadError
    end
    begin
      require robot
    rescue LoadError
  end
  in_game_name = File.basename(robot).sub(/\..*$/, '')
  in_game_name[0] = in_game_name[0,1].upcase
  team = c / team_divider
  c += 1
  robotrunner = RobotRunner.new(Object.const_get(in_game_name).new, battlefield, team)
  battlefield << robotrunner
  rescue Exception => error
    puts 'Error loading ' + robot + '!'
    warn error
    usage
  end
  in_game_name
end

if mode == :run_out_of_gui
  run_out_of_gui(battlefield)
else
  run_in_gui(battlefield, xres, yres, speed_multiplier)
end
