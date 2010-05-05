require 'tk'
require 'base64'

TkRobot = Struct.new(:body, :gun, :radar, :speech, :info, :status)

class TkArena

  attr_reader :battlefield, :xres, :yres
  attr_accessor :speed_multiplier, :on_game_over_handlers
  attr_accessor :canvas, :boom, :robots, :bullets, :explosions, :colors
  attr_accessor :default_skin_prefix

  def initialize battlefield, xres, yres, speed_multiplier
    @battlefield = battlefield
    @xres, @yres = xres, yres
    @speed_multiplier = speed_multiplier
    @text_colors = ['#ff0000', '#00ff00', '#0000ff', '#ffff00', '#00ffff', '#ff00ff', '#ffffff', '#777777']
    @default_skin_prefix = File.join(File.dirname(__FILE__),"images/red_")
    @on_game_over_handlers = []
    init_canvas
    init_simulation
  end

  def on_game_over(&block)
    @on_game_over_handlers << block
  end

  def read_gif name, c1, c2, c3
    data = nil
    open(name, 'rb') do |f|
      data = f.read()
      ncolors = 2**(1 + data[10].ord[0] + data[10].ord[1] * 2 + data[10].ord[2] * 4)
      ncolors.times do |j|
        data[13 + j * 3 + 0], data[13 + j * 3 + 1], data[13 + j * 3 + 2] =
          data[13 + j * 3 + c1], data[13 + j * 3 + c2], data[13 + j * 3 + c3]
      end
    end
    TkPhotoImage.new(:data => Base64.encode64(data))
  end

  def usage
    puts "usage: rrobots.rb <FirstRobotClassName[.rb]> <SecondRobotClassName[.rb]> <...>"
    puts "\tthe names of the rb files have to match the class names of the robots"
    puts "\t(up to 8 robots)"
    puts "\te.g. 'ruby rrobots.rb SittingDuck NervousDuck'"
    exit
  end

  def init_canvas
    @canvas = TkCanvas.new(:height=>yres, :width=>xres, :scrollregion=>[0, 0, xres, yres], :background => '#000000').pack
    @colors = []
    [[0,1,1],[1,0,1],[1,1,0],[0,0,1],[1,0,0],[0,1,0],[0,0,0],[1,1,1]][0...@battlefield.robots.length].zip(@battlefield.robots) do |color, robot|
      bodies, guns, radars = [], [], []
      image_path = robot.skin_prefix || @default_skin_prefix
      reader = robot.skin_prefix ? lambda{|fn| TkPhotoImage.new(:file => fn) } : lambda{|fn| read_gif(fn, *color)}
      36.times do |i|
        bodies << reader["#{image_path}body#{(i*10).to_s.rjust(3, '0')}.gif"]
        guns << reader["#{image_path}turret#{(i*10).to_s.rjust(3, '0')}.gif"]
        radars << reader["#{image_path}radar#{(i*10).to_s.rjust(3, '0')}.gif"]
      end
      @colors << TkRobot.new(bodies << bodies[0], guns << guns[0], radars << radars[0])
    end

    @boom = (0..14).map do |i|
      TkPhotoImage.new(:file => File.join(File.dirname(__FILE__), "images/explosion#{i.to_s.rjust(2, '0')}.gif"))
    end
  end

  def init_simulation
    @robots, @bullets, @explosions = {}, {}, {}
    TkTimer.new(20, -1, Proc.new{
      begin
        draw_frame
      rescue => err
        puts err.class, err, err.backtrace
        raise
      end
    }).start
  end

  def draw_frame
    simulate(@speed_multiplier)
    draw_battlefield
  end

  def simulate(ticks=1)
    @explosions.reject!{|e,tko| @canvas.delete(tko) if e.dead; e.dead }
    @bullets.reject!{|b,tko| @canvas.delete(tko) if b.dead; b.dead }
    @robots.reject! do |ai,tko|
      if ai.dead
        tko.status.configure(:text => "#{ai.name.ljust(20)} dead")
        tko.each{|part| @canvas.delete(part) if part != tko.status}
        true
      end
    end
    ticks.times do
      if @battlefield.game_over
        @on_game_over_handlers.each{|h| h.call(@battlefield) }
        unless @game_over
          winner = @robots.keys.first
          whohaswon = if winner.nil?
            "Draw!"
          elsif @battlefield.teams.all?{|k,t|t.size<2}
            "#{winner.name} won!"
          else
            "Team #{winner.team} won!"
          end
          text_color = winner ? winner.team : 7
          @game_over = TkcText.new(canvas,
            :fill => @text_colors[text_color],
            :anchor => 'c', :coords => [400,400], :font=>'courier 36', :justify => 'center',
            :text => "GAME OVER\n#{whohaswon}")
        end
      end
      @battlefield.tick
    end
  end

  def draw_battlefield
    draw_robots
    draw_bullets
    draw_explosions
  end

  def draw_robots
    @battlefield.robots.each_with_index do |ai, i|
      next if ai.dead
      @robots[ai] ||= TkRobot.new(
        TkcImage.new(@canvas, 0, 0),
        TkcImage.new(@canvas, 0, 0),
        TkcImage.new(@canvas, 0, 0),
        TkcText.new(@canvas,
        :fill => @text_colors[ai.team],
        :anchor => 's', :justify => 'center', :coords => [ai.x / 2, ai.y / 2 - ai.size / 2]),
        TkcText.new(@canvas,
        :fill => @text_colors[ai.team],
        :anchor => 'n', :justify => 'center', :coords => [ai.x / 2, ai.y / 2 + ai.size / 2]),
        TkcText.new(@canvas,
        :fill => @text_colors[ai.team],
        :anchor => 'nw', :coords => [10, 15 * i + 10], :font => TkFont.new("courier 9")))
      @robots[ai].body.configure( :image => @colors[ai.team].body[(ai.heading+5) / 10],
                                  :coords => [ai.x / 2, ai.y / 2])
      @robots[ai].gun.configure(  :image => @colors[ai.team].gun[(ai.gun_heading+5) / 10],
                                  :coords => [ai.x / 2, ai.y / 2])
      @robots[ai].radar.configure(:image => @colors[ai.team].radar[(ai.radar_heading+5) / 10],
                                  :coords => [ai.x / 2, ai.y / 2])
      @robots[ai].speech.configure(:text => "#{ai.speech}",
                                   :coords => [ai.x / 2, ai.y / 2 - ai.size / 2])
      @robots[ai].info.configure(:text => "#{ai.name}\n#{'|' * (ai.energy / 5)}",
                                 :coords => [ai.x / 2, ai.y / 2 + ai.size / 2])
      @robots[ai].status.configure(:text => "#{ai.name.ljust(20)} #{'%.1f' % ai.energy}")
    end
  end

  def draw_bullets
    @battlefield.bullets.each do |bullet|
      @bullets[bullet] ||= TkcOval.new(
        @canvas, [-2, -2], [3, 3],
        :fill=>'#'+("%02x" % (128+bullet.energy*14).to_i)*3)
      @bullets[bullet].coords(
        bullet.x / 2 - 2, bullet.y / 2 - 2,
        bullet.x / 2 + 3, bullet.y / 2 + 3)
    end
  end

  def draw_explosions
    @battlefield.explosions.each do |explosion|
      @explosions[explosion] ||= TkcImage.new(@canvas, explosion.x / 2, explosion.y / 2)
      @explosions[explosion].image(boom[explosion.t])
    end
  end

  def run
    Tk.mainloop
  end

end
