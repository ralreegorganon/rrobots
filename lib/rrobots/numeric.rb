##
# Numeric extensions for rrobots.

class Numeric
  TO_RAD = Math::PI / 180.0 # :nodoc:
  TO_DEG = 180.0 / Math::PI # :nodoc:

  ##
  # Convert degrees to radians.

  def to_rad
    self * TO_RAD
  end

  ##
  # Convert radians to degrees.

  def to_deg
    self * TO_DEG
  end
end
