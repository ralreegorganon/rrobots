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