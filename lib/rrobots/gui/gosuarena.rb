require 'gosu'

BIG_FONT = 'Courier New'
SMALL_FONT = 'Courier New'
COLORS = ['white', 'blue', 'yellow', 'red', 'lime'] 
FONT_COLORS = [0xffffffff, 0xff0008ff, 0xfffff706, 0xffff0613, 0xff00ff04]
    
GosuRobot = Struct.new(:body, :gun, :radar, :speech, :info, :status, :color, :font_color)

module ZOrder
  Background, Robot, Explosions, UI = *0..3
end

class RRobotsGameWindow < Gosu::Window
  attr_reader :battlefield, :xres, :yres
  attr_accessor :on_game_over_handlers, :boom, :robots, :bullets, :explosions
  
  def initialize(battlefield, xres, yres)
    super(xres, yres, false, 16)
    self.caption = 'RRobots'
    @font = Gosu::Font.new(self, BIG_FONT, 24)
    @small_font = Gosu::Font.new(self, SMALL_FONT, 24) #xres/100
    @background_image = Gosu::Image.new(self, File.join(File.dirname(__FILE__),"../images/space.png"), true)
    @battlefield = battlefield
    @xres, @yres = xres, yres
    @on_game_over_handlers = []
    init_window
    init_simulation
    @leaderboard = Leaderboard.new(self, @robots)
  end

  def on_game_over(&block)
    @on_game_over_handlers << block
  end
  
  def init_window
    @boom = (0..14).map do |i|
      Gosu::Image.new(self, File.join(File.dirname(__FILE__),"../images/explosion#{i.to_s.rjust(2, '0')}.bmp"))
    end
    @bullet_image = Gosu::Image.new(self, File.join(File.dirname(__FILE__),"../images/bullet.png"))
  end
  
  def init_simulation
    @robots, @bullets, @explosions = {}, {}, {}
  end

  def draw
    simulate
    draw_battlefield
    @leaderboard.draw
    if button_down? Gosu::Button::KbEscape
      self.close
    end
  end

  def draw_battlefield
    draw_robots
    draw_bullets
    draw_explosions
  end
  
  def simulate(ticks=1)
    @explosions.reject!{|e,tko| e.dead }
    @bullets.reject!{|b,tko| b.dead }
    @robots.reject! { |ai,tko| ai.dead}
    ticks.times do
      if @battlefield.game_over
        @on_game_over_handlers.each{|h| h.call(@battlefield) }
          winner = @robots.keys.first
          whohaswon = if winner.nil?
            "Draw!"
          elsif @battlefield.teams.all?{|k,t|t.size<2}
            "#{winner.name} won!"
          else
            "Team #{winner.team} won!"
          end
          text_color = winner ? winner.team : 7
          @font.draw_rel("#{whohaswon}", xres/2, yres/2, ZOrder::UI, 0.5, 0.5, 1, 1, 0xffffff00)
      end
      @battlefield.tick
    end
  end
  
  def draw_robots
    @battlefield.robots.each_with_index do |ai, i|
      next if ai.dead
      col = COLORS[i % COLORS.size]
      font_col = FONT_COLORS[i % FONT_COLORS.size]
      @robots[ai] ||= GosuRobot.new(
        Gosu::Image.new(self, File.join(File.dirname(__FILE__),"../images/#{col}_body000.bmp")),
        Gosu::Image.new(self, File.join(File.dirname(__FILE__),"../images/#{col}_turret000.bmp")),
        Gosu::Image.new(self, File.join(File.dirname(__FILE__),"../images/#{col}_radar000.bmp")),
        @small_font,
        @small_font,
        @small_font,
        col,
        font_col
      )
      @robots[ai].body.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.heading-90)) % 360)
      @robots[ai].gun.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.gun_heading-90)) % 360)
      @robots[ai].radar.draw_rot(ai.x / 2, ai.y / 2, ZOrder::Robot, (-(ai.radar_heading-90)) % 360)
      
      @robots[ai].speech.draw_rel(ai.speech.to_s, ai.x / 2, ai.y / 2 - 40, ZOrder::UI, 0.5, 0.5, 1, 1, font_col)
      @robots[ai].info.draw_rel("#{ai.name}", ai.x / 2, ai.y / 2 + 30, ZOrder::UI, 0.5, 0.5, 1, 1, font_col)
      @robots[ai].info.draw_rel("#{ai.energy.to_i}", ai.x / 2, ai.y / 2 + 50, ZOrder::UI, 0.5, 0.5, 1, 1, font_col)
    end
  end

  def draw_bullets
    @battlefield.bullets.each do |bullet|
      @bullets[bullet] ||= @bullet_image
      @bullets[bullet].draw(bullet.x / 2, bullet.y / 2, ZOrder::Explosions)
    end
  end

  def draw_explosions
    @battlefield.explosions.each do |explosion|
      @explosions[explosion] = boom[explosion.t % 14]
      @explosions[explosion].draw_rot(explosion.x / 2, explosion.y / 2, ZOrder::Explosions, 0)
    end
  end
end


