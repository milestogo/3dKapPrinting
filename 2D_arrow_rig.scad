
/// Constants
inchmm=25.4; // mm per inch
epsilon=0.01;//amount of fudge needed to avoid manifold problems. 
fudge=.01; // size to increase all hole diameters to deal with shrinkage. 

//bolt hole diameter for hinge pivot points
pivot_bolt=3.5+fudge; // #6 bolt .138 in /32

// washer height (pivot bolts) // Set to the distance between the top of servo and bottom of gear. 
washerH=11.25;
//washer diam (around bolt holes)
washerD=5;

// Outer diameter of the spar - we assume same spar for both angles. 
spar_diameter=(0.297*inchmm)+fudge;
//=0.298*inchmm; // SKyshark p400
//=0.284*inchmm; // SKyshark p200
//=0.280*inchmm; // SKyshark p100
//=0.289*inchmm; // SKyshark p2x
//=0.298*inchmm; // SKyshark p4x?

// If we are using flat sheet instead of spars, what is its width?
plate_width=22; ///inchmm*3/4;
plate_height=inchmm/16+.6; // height==thickness of AL sheet. big fudge, since you really don't want it to be too small. 

// mm of material for wall around a spar
wall=2.5;
2dWall=8; // how much margin between holes in laser cut parts. 

// how big should the rectangular brace between spars be? 
size=10; // thickness & starting width of brace that separates shafts & has holes put through it. 

// diameter size of zip tie/bolt hole for parts that cap over the end of a shaft. 
zip=3;

// Diameter of a camera bolt
camera_bolt_d=(.25*inchmm)+.1;// this will usually be pretty tight, enough for a bit of tapping. 

// HITEC HS-5055MG measurements https://www.servocity.com/html/hs-5055mg_servo.html
servo_narrow=11.6+fudge;
servo_wide=22.8+fudge;
servo_depth=24; //TODO VERIFY
servo_screws=0.078*inchmm+fudge/2; // TODO VERIFY
servo_screw_offset=2.28; //TODO VERIFY )(1.115-0.935)/2)*25.4
servo_offset=4.5; // distance from center of servo shaft to nearest short width of the servo.

// HItech HS-85MG - micro
servo_narrow=13+fudge;
servo_wide=29+fudge;
servo_depth=.78*inchmm; //TODO VERIFY
servo_screws=0.078*inchmm+fudge/2; // TODO VERIFY
servo_screw_offset=2.28; //TODO VERIFY )(1.115-0.935)/2)*25.4
servo_offset=6; // distance from center of servo shaft to nearest short width of the servo.
// spar distance (how far apart does this set of spars need to be to accomodate a servo or inner set of spars?)
spar_distance=servo_wide+ 2*wall; // inner pair of spars

//  Do we want to put in some big holes to lighten the servo holder? 
do_servo_lightening=1;

///// Calculated fields
cylwidth=spar_diameter+2*wall; 
inner_spar_offset=(servo_wide+2*wall)/2; // half of the needed distance
outer_spar_offset=(spar_diameter+inner_spar_offset );  //we want overlap of wall, not spars. 


/* Required for the 2d swing arm calculations */
camera_height=65; 
camera_v_mass_point=31; // How distance between bottom of camera and pivot point 

module PivotSidePlate (offset, shaft_d, margin, zip,do_inner, do_servo){ // Margin is the Wall size around holes
partwidth=servo_narrow+2*margin;
topbell=((shaft_d)/2)+1.2*margin;
header=55; // minimumn distance between spars and top of camera (size of AA batteries?)
footer=20; // distance between bottom of camera and ground ; 
pivot_point=header+camera_height-camera_v_mass_point;//
pu=servo_narrow*.75;
difference() {
	
		union() {
		  hull(){
			for (direction = [1, -1])  {
	     		   translate([direction * offset, 0, 0])  
			   			circle( topbell ,center=true,$fs=0.5);		
				} //for
			translate([0,20,0])
				circle( topbell ,center=true,$fs=0.5);
			} //hull
			translate([-partwidth/2,0,0])
				square ([partwidth,header+camera_height+footer]);
			translate([0,header+camera_height+footer,0])
				hull(){
					for (direction = [1, -1])  {
		     		   translate([direction * offset, 0, 0])  
				   			circle( (shaft_d+2)/2 ,center=true,$fs=0.5);		
					} //for
				}//hull
			
		}// union
		// Spar holes
		for (direction = [1, -1])  {
	     		   translate([direction * offset, 0, 0])  
					if(1==do_inner){
			   			circle((zip)/2,center=true,$fs=0.5);		
					} else {
						circle((shaft_d)/2,center=true,$fs=0.5);
					}
		} //for

		// Top ornament
		translate([0,-1.3*topbell,0])
				circle(topbell);
		translate ([0,-.3*topbell/2,0]) {
			circle((servo_narrow)/2);
		}
		// bottom ornament
		/* translate([0,header+camera_height+footer+shaft_d/2]) {
			circle(shaft_d*1.5);
            translate ([0,-2*shaft_d,0]) 
                circle((servo_narrow)/2);
		} */


		//lightening
		*translate([0,header+camera_height-2*servo_narrow,0])
				circle(servo_narrow/2 ,center=true,$fs=0.5);

		for (count = [ 15 :pu: (pivot_point-margin-servo_offset)]){
				foo=(ceil(count/pu)%2);
                 echo(count);
                if( 1== (foo) ) { 
                    translate([-pu/2, count, 0]) 
                        circle((pu)/2);
            
                }else {
                    translate([pu/2, count, 0]) 
                        circle((pu)/2);
            
                }
		}

		

		// Servo hole
		if(1==do_servo){
            translate([-servo_narrow/2,pivot_point-servo_offset,0]) {
				*circle(pivot_bolt,center=true);
                square([servo_narrow,servo_wide]);
            }
            hull(){ // lightening hole in footer area
                translate([0,pivot_point+1.2*margin+servo_wide,0]) 
                    circle(servo_narrow/2);
                translate([0,header+footer+camera_height-2*margin,0])
                     circle(servo_narrow/2);
                }
           
		} else {// we're a hinge point
			translate([0,pivot_point,0]) 
				circle(pivot_bolt,center=true);
            hull(){ // lightening hole in footer area
                translate([0,pivot_point+margin+servo_narrow,0]) 
                    circle(servo_narrow/2);
                translate([0,header+footer+camera_height-2*margin,0])
                     circle(servo_narrow/2);
                }
            }
            
       if (3==do_inner) { // whack off the feet for cost & weight savings
           translate([-50,pivot_point+servo_wide+margin,0]) 
               square([100,100]);
           
           
       }
	}// difference
}

PivotSidePlate(outer_spar_offset,spar_diameter,2dWall,zip,0,0);
translate([100,0,0])
	PivotSidePlate(outer_spar_offset,spar_diameter,2dWall,zip,1,1);

translate([200,0,0])
    PivotSidePlate(outer_spar_offset,spar_diameter,2dWall,zip,0,1);
translate([300,0,0])
	PivotSidePlate(outer_spar_offset,spar_diameter,2dWall,zip,1,0);