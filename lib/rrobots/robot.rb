module Robot

  def self.attr_state(*names)
    names.each{|n|
      n = n.to_sym
      attr_writer n
      attr_reader n
    }
  end

  def self.attr_action(*names)
    names.each{|n|
      n = n.to_sym
      define_method(n){|param| @actions[n] = param }
    }
  end

  def self.attr_event(*names)
    names.each{|n|
      n = n.to_sym
      define_method(n){ @events[n] }
    }
  end

  #the state hash of your robot. also accessible through the attr_state methods
  attr_accessor :state

  #the action hash of your robot
  attr_accessor :actions

  #the event hash of your robot
  attr_accessor :events

  #path to where your robot's optional skin images are
  attr_accessor :skin_prefix

  #team of your robot
  attr_state :team

  #the height of the battlefield
  attr_state :battlefield_height

  #the width of the battlefield
  attr_state :battlefield_width

  #your remaining energy (if this drops below 0 you are dead)
  attr_state :energy

  #the heading of your gun, 0 pointing east, 90 pointing north, 180 pointing west, 270 pointing south
  attr_state :gun_heading

  #your gun heat, if this is above 0 you can't shoot
  attr_state :gun_heat

  #your robots heading, 0 pointing east, 90 pointing north, 180 pointing west, 270 pointing south
  attr_state :heading

  #your robots radius, if x <= size you hit the left wall
  attr_state :size

  #the heading of your radar, 0 pointing east, 90 pointing north, 180 pointing west, 270 pointing south
  attr_state :radar_heading

  #ticks since match start
  attr_state :time

  #whether the match is over or not, remember to go into cheer mode when this is true ;)
  attr_state :game_over

  #your speed (-8..8)
  attr_state :speed
  alias :velocity :speed

  #your x coordinate, 0...battlefield_width
  attr_state :x

  #your y coordinate, 0...battlefield_height
  attr_state :y

  #accelerate (max speed is 8, max accelerate is 1/-1, negativ speed means moving backwards)
  attr_action :accelerate

  #accelerates negativ if moving forward (and vice versa), may take 8 ticks to stop (and you have to call it every tick)
  def stop
    accelerate((speed > 0) ? -1 : ((speed < 0) ? 1 :0))
  end

  #fires a bullet in the direction of your gun, power is 0.1 - 3, this power is taken from your energy
  attr_action :fire

  #turns the robot (and the gun and the radar), max 10 degrees per tick
  attr_action :turn

  #turns the gun (and the radar), max 30 degrees per tick
  attr_action :turn_gun

  #turns the radar, max 60 degrees per tick
  attr_action :turn_radar

  #broadcast message to other robots
  attr_action :broadcast

  #say something to the spectators
  attr_action :say

  #if you got hit last turn, this won't be empty
  attr_event :got_hit

  #distances to robots your radar swept over during last tick
  attr_event :robot_scanned

  #broadcasts received last turn
  attr_event :broadcasts

end
