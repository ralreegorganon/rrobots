##
# This is the module you must include in your AI class in order to
# have a working robot. It provides all of the state, event, and
# actions that a bot may perform in the game.
#
# These methods are intentionally of very basic nature, you are free
# to unleash the whole power of ruby to create higher level functions.
# (e.g. move_to, fire_at and so on)
#
# Some words of explanation: The gun is mounted on the body, if you
# turn the body the gun will follow. In a similar way the radar is
# mounted on the gun. The radar scans everything it sweeps over in a
# single tick (100 degrees if you turn your body, gun and radar in the
# same direction) but will report only the distance of scanned robots,
# not the angle. If you want more precision you have to turn your
# radar slower.
#
# You must implement Robot#tick for your AI to respond to the game.

module Robot
  def self.attr_state(*names) # :nodoc:
    names.each{|n|
      n = n.to_sym
      attr_writer n
      attr_reader n
    }
  end

  def self.attr_action(*names) # :nodoc:
    names.each{|n|
      n = n.to_sym
      define_method(n){|param| @actions[n] = param }
    }
  end

  def self.attr_event(*names) # :nodoc:
    names.each{|n|
      n = n.to_sym
      define_method(n){ @events[n] }
    }
  end

  ##
  # The state hash of your robot. also accessible through the attr_state methods.

  attr_accessor :state

  ##
  # The action hash of your robot.

  attr_accessor :actions

  ##
  # The event hash of your robot.

  attr_accessor :events

  ##
  # Path to where your robot's optional skin images are.

  attr_accessor :skin_prefix

  ##
  # Team of your robot.
  #
  # :attr_reader: team

  attr_state :team

  ##
  # The height of the battlefield.
  #
  # :attr_reader: battlefield_height

  attr_state :battlefield_height

  ##
  # The width of the battlefield.
  #
  # :attr_reader: battlefield_width

  attr_state :battlefield_width

  ##
  # Your remaining energy (if this drops below 0 you are dead).
  #
  # :attr_reader: energy

  attr_state :energy

  ##
  # The heading of your gun, 0 pointing east, 90 pointing north, 180
  # pointing west, 270 pointing south.
  #
  # :attr_reader: gun_heading

  attr_state :gun_heading

  ##
  # Your gun heat, if this is above 0 you can't shoot.
  #
  # :attr_reader: gun_heat

  attr_state :gun_heat

  ##
  # Your robots heading, 0 pointing east, 90 pointing north, 180
  # pointing west, 270 pointing south.
  #
  # :attr_reader: heading

  attr_state :heading

  ##
  # Your robots radius, if x <= size you hit the left wall.
  #
  # :attr_reader: size

  attr_state :size

  ##
  # The heading of your radar, 0 pointing east, 90 pointing north, 180
  # pointing west, 270 pointing south.
  #
  # :attr_reader: radar_heading

  attr_state :radar_heading

  ##
  # Ticks since match start.
  #
  # :attr_reader: time

  attr_state :time

  ##
  # Whether the match is over or not, remember to go into cheer mode
  # when this is true ;).
  #
  # :attr_reader: game_over

  attr_state :game_over

  ##
  # Your speed (-8..8).
  #
  # :attr_reader: speed

  attr_state :speed

  alias :velocity :speed

  ##
  # The AI's event handler. You *must* override this method.

  def tick event
    raise NotImplementedError, "Subclass responsibility to implement #tick"
  end

  ##
  # Your x coordinate, 0...battlefield_width.
  #
  # :attr_reader: x

  attr_state :x

  ##
  # Your y coordinate, 0...battlefield_height.
  #
  # :attr_reader: y

  attr_state :y

  ##
  # Accelerate (max speed is 8, max accelerate is 1/-1, negative speed
  # means moving backwards).
  #
  # :method: accelerate
  # :arg: amount

  attr_action :accelerate

  ##
  # Decelerates if moving forward (and vice versa), may take 8 ticks
  # to stop (and you have to call it every tick).

  def stop
    accelerate((speed > 0) ? -1 : ((speed < 0) ? 1 :0))
  end

  ##
  # Fires a bullet in the direction of your gun, power is 0.1 - 3,
  # this power is taken from your energy.
  #
  # :method: fire
  # :arg: power

  attr_action :fire

  ##
  # Turns the robot (and the gun and the radar), max 10 degrees per tick.
  #
  # :method: turn
  # :arg: angle

  attr_action :turn

  ##
  # Turns the gun (and the radar), max 30 degrees per tick.
  #
  # :method: turn_gun
  # :arg: angle

  attr_action :turn_gun

  ##
  # Turns the radar, max 60 degrees per tick.
  #
  # :method: turn_radar
  # :arg: angle

  attr_action :turn_radar

  ##
  # Broadcast message to other robots.
  #
  # :method: broadcast
  # :arg: msg

  attr_action :broadcast

  ##
  # Say something to the spectators.
  #
  # :method: say
  # :arg: msg

  attr_action :say

  ##
  # If you got hit last turn, this won't be empty.
  #
  # :attr_reader: got_hit

  attr_event :got_hit

  ##
  # Distances to robots your radar swept over during last tick.
  #
  # :attr_reader: robot_scanned

  attr_event :robot_scanned

  ##
  # Broadcasts received last turn.
  #
  # :attr_reader: broadcasts

  attr_event :broadcasts
end
