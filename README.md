# This is a library of parts for printing KAP rigs. 
# With arrow shafts of the right length & these parts, customizing a rig should be simple. 
# The parts are the right shape. Making them strong, light & durable enough is up to you. 

# Most things you want to do can be adjusted using the variables in the first part of the OpenScad file
# If you want gears, you want to download & install http://www.thingiverse.com/thing:3575
# Huge thanks to Cliff L. Biffle's magic function to generate gears using center distance 
#  http://www.thingiverse.com/thing:6894

## Parts so far
# Pars of  Pan or tilt gears
# A shape to hold a servo between two shafts. ServoHolder()
# A shape to hold something between two shafts. Could be a pivot point for the picavet, or the bottom plate that holds the camera between two pairs of shafts.BracePivot()
# A dumb plate for mounting cameras or parts between shafts. CameraPlate()
# A corner connector between two pairs of shafts at 90 degrees. pipebrace()
# a hinge in two parts. hinge_pintle(), hinge_gudgeon()
# Gears directly connected to a BracePivot(): GearedTiltPivot
# A special shape that combines a gear with a plate to rotate camera on it's true center of mass. DirectCameraPivot()

###  TODO
# add a 2 axis center of mass plate for HoVer
# Dynamic spreader parts


