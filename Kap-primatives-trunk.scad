// Parametric  KAP rig
// CPHLewis, Myles, 2014

// You can get this file from http://www.thingiverse.com/thing:3575
use <parametric_involute_gear_v5.0.scad>

/// Constants
inchmm=25.4; // mm per inch
epsilon=0.01;//amount of fudge needed to avoid manifold problems. 
fudge=.3; // size to increase all hole diameters to deal with shrinkage. 

//bolt hole diameter for hinge pivot points
pivot_bolt=3.5+.2; // #6 bolt .138 in /32

// washer height (pivot bolts) // Set to the distance between the top of servo and bottom of gear. 
washerH=11.25;
//washer diam (around bolt holes)
washerD=5;

// Outer diameter of the spar - we assume same spar for both angles. 
spar_diameter=(0.3*inchmm)+fudge;
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
// how big should the rectangular brace between spars be? 
size=10; // thickness & starting width of brace that separates shafts & has holes put through it. 

// diameter size of zip tie/bolt hole for parts that cap over the end of a shaft. 
zip=3;

// Camera offsets - distance between center of mass & the camera thread
//Canon S100 = 9, Sony a5000=~12?
cam_offset=9;

// Diameter of a camera bolt
camera_bolt_d=(.25*inchmm)+.1;// this will usually be pretty tight, enough for a bit of tapping. 

// HITEC HS-5055MG measurements https://www.servocity.com/html/hs-5055mg_servo.html
servo_narrow=11.6+fudge;
servo_wide=22.8+fudge;
servo_depth=24; //TODO VERIFY
servo_screws=0.078*inchmm+fudge/2; // TODO VERIFY
servo_screw_offset=2.28; //TODO VERIFY )(1.115-0.935)/2)*25.4


// spar distance (how far apart does this set of spars need to be to accomodate a servo or inner set of spars?)
spar_distance=servo_wide+ 2*wall; // inner pair of spars

//  Do we want to put in some big holes to lighten the servo holder? 
do_servo_lightening=1;

///// Calculated fields
cylwidth=spar_diameter+2*wall; 
inner_spar_offset=(servo_wide+2*wall)/2; // half of the needed distance
outer_spar_offset=(spar_diameter+inner_spar_offset );  //we want overlap of wall, not spars. 

//// Borrowed Gear functions. 
// Copyright 2011 Cliff L. Biffle. http://www.thingiverse.com/thing:6894
// This file is licensed Creative Commons Attribution-ShareAlike 3.0.
function sqr(n) = pow(n, 2);
function cube(n) = pow(n, 3);
function gear_outer_radius(number_of_teeth, circular_pitch) =
	(sqr(number_of_teeth) * sqr(circular_pitch) + 64800)
		/ (360 * number_of_teeth * circular_pitch);
function fit_spur_gears(n1, n2, spacing) =
	(180 * spacing * n1 * n2  +  180
		* sqrt(-(2*n1*cube(n2)-(sqr(spacing)-4)*sqr(n1)*sqr(n2)+2*cube(n1)*n2)))
	/ (n1*sqr(n2) + sqr(n1)*n2);

//http://svn.clifford.at/openscad/trunk/libraries/shapes.scad
module hexagon(size, height) {
  boxWidth = size/1.75;
  for (r = [-60, 0, 60]) rotate([0,0,r]) cube([boxWidth, size, height], true);
}

//////////////////////////////



///// Servo Holder
module ServoHolder(offset, shaft_d,,do_lighten){
  length = 2*offset+cylwidth; // width of basic shape
  height=size+1.5*wall+servo_wide;
  drillium=do_lighten*((((size+cylwidth+servo_wide)*do_lighten/2)-2*wall)/2);// radius of lightening hole

  difference() {
    hull() {
		union(){
	  		cube([servo_narrow + 2*wall, size, servo_wide + 4*wall],center=true); // slightly bigger than servo
	
      		for (direction = [1, -1])  { // left & right spars
          		translate([direction * offset, 0, 0])  
		   			cylinder(h=height, r=(spar_diameter+wall)/2,center=true,$fs=0.5);			
      		} //for
		} //union of solid parts
   } // end of hull
   
  union(){ // all holes
	rotate([-90, 0,0]) 
			cube([servo_narrow,servo_wide,size+2], center=true); //space for servo

    for (direction = [1, -1])  {
        translate([direction * offset, 0, 0])  { // shaft supports
					cylinder(h=(height*1.5), r=(spar_diameter)/2, center=true, $fs=0.5);
		}
        rotate([-90, 0,0]) {

              // lightening holes
			translate([direction*height/2,0,0]) {
				union(){
					cylinder(h=size*3,r=drillium ,center=true,$fs=0.5);
					translate([direction*drillium/2,0,0])
						cube([drillium,2*drillium,size*2],center=true); 
				}
			}
       
	   		 translate([0,direction*(servo_wide/2 + servo_screw_offset),0], center=true)
                    	 cylinder(h=20, r=servo_screws/2, $fs=0.5);  //servo screw holes
		 }
		} // direction      
   } //union of holes
 } //difference

} //module		
	
	
// Massively overloaded function for creating a bar shaped thing that has a pivot hinge in the middle and connects to struts or sheet metal.  
module BracePivot(offset,shaft_d,bolt_d,gear_bushing_height,do_plate,plate_width,plate_height)
//  offset is distance between shafts.  Bolt_d is center pivot bolt. 
//  do_plate is 0,H,V or P. 0 assumes poles perpendicular to the pivot 
////  H is a plate perpendicular to the pivot, as you might want to hold a U shaped metal frame for a horizontal rig. 
////  V is for a plate parallel to the pivot point, as for holding a plate at the end of two spars. 
////  P  is notched on one side and could possibly be useful for directly holding a small powershot  Disrecommended. 
//  
{
  length =  4*wall+ washerD; // How wide should the part be along the long spar axis?
  washer_cyl=gear_bushing_height+size/2; // bushing height from base.
  
  difference() {

	union(){ // all the solids
  	  	hull() {
			cube([length, size, size], center=true);
	
    			for (direction = [1, -1])  {
     		   translate([direction * offset, 0, 0])  {
		   			cylinder(h=length, r=(shaft_d+2*wall)/2,center=true,$fs=0.5);		
					
		   			*rotate([90,0,0]){
						translate([0,size/2],0)
								cylinder(h=size, r=size *5/8, $fs=0.5, center=true);
						translate([0,-size/2,0]) 
								cylinder(h=size, r=size*5/8, $fs=0.5, center=true);
					} // rotate
			
     	 		} // translate
			} //for
		 
			// bolt washer
 	 		rotate([-90, 0,0]) 
				//translate([0,0,size/2])
	 				cylinder(h=washer_cyl,r=washerD,$fs=0.5);
  		} //hull
	} //union 

	union(){ // all the holes
   	 	if( do_plate != "H" && do_plate !="P" ){
				for (direction = [1, -1])  {
        			translate([direction * offset, 0, 0])  {
						cylinder(h=(length*3), r=shaft_d/2, center=true, $fs=0.5);
					}
				}
			 
			} else { //horizontal plate instead of spars 
				rotate([90,0,0]){
					if ("P"==do_plate ) {
						translate([-plate_width/2,-2*size,0])
							cube([plate_width,9*length,length]);
					} else {
						cube([plate_width,9*length,plate_height],center=true);
					}
				}
		}
		if("V"==do_plate ){
				cube([plate_width,9*length,plate_height],center=true);	
		} 

 	 } //union

 	// bolt hole
 	 rotate([-90, 0,0])  {
	 		cylinder(h=washer_cyl*3,r=bolt_d/2,center=true,$fs=0.5);

	// lightening /strengthening holes 
		if(0==do_plate) {
			if(offset == outer_spar_offset) {
				for (direction = [1, -1])  {
        			translate([direction * (offset)/2, 0, 0])  
						cube([size*(1/2),size/3,size*9], center=true);
				}
			} 
		} else { //pilot holes for pins. 
			if ("H"==do_plate || "P"==do_plate ){
				for (direction = [1, -1])  {
        				translate([direction * plate_width/3, 0, 0])  {
						cylinder(h=(length*3), r=1, center=true, $fs=0.5);
						}
				}
				if ("P"==do_plate) { // lop off one lobe of the holder
						translate([plate_width/2,-size,-size]) 
							cube([size,2*size,(size-3)]);
				}
			} 
			if ("V"==do_plate ){
				rotate([90,0,0]){
					for (direction = [1, -1])  {
        					translate([direction * plate_width/3, 0, 0])  {
									cylinder(h=(length*3), r=1, center=true, $fs=0.5);
							}
					}
				} 
			}
		}
	  }//rotate
 	} //difference

} //module		


//// Plate for a camera to rest on. This is kind of heavy & poorly designed. 
// Hard coded plate length is 3 inches 		
// bolt_offset is from center. 
// do_slots makes big rectangles 
module CameraPlate(offset,shaft_d,bolt_offset,do_slots)
{

  length =  2*inchmm; // How wide should the part along the long spar axis?
  camerabolt=.25*inchmm+.01; // assumes 1/4 inch bolt & not tapping the plastic much. 

  difference() {

	union(){ // all the solids
		translate([0,((cylwidth/2)-wall),0])
				cube([(offset+2*cylwidth), wall,length], center=true);
	
    		for (direction = [1, -1])  {
     		   translate([direction * offset, 0, 0])  
		   			cylinder(h=length, r=(shaft_d+wall)/2,center=true,$fs=0.5);		
			} //for
	} //union 

	union(){ // all the holes
    	for (direction = [1, -1])  {
        	translate([direction * offset, 0, 0])  {
					cylinder(h=(length*3), r=shaft_d/2, center=true, $fs=0.5);
			}

		} //for

		// bolt hole. Assumes 1/4 inch bolt/
		translate([0,0,-length/2]){ 
			rotate([90, 0,0]) {
				for (direction = [camerabolt : 2*camerabolt : length-2*camerabolt ])  {
					translate([0,direction,0])
	 					cylinder(h=size*2,r=camerabolt/2,center=true,$fs=0.5);
				}
			}
		}
 	 } //union

 	
  } //difference


} //module	



// PipeBrace - corner parts for connecting two sets of shafts at a 90 degree angle. Print with 3-4 shells for strength.
	
//ARGS: 
// PP determines if the two sets are the same distance appart but offset (O) or (P) for parallel/2 distances
// ,inner_offset betweeen walls of inner pair of  spars  
////   height of raised washer for bolt, bolt diameter for pivot, diameter of zip tie/screw at end of spar. 
module pipebrace(PO, inner_offset, pole, washer_height,bolt_diameter,zip)
{
length = 2*inner_offset+(cylwidth*2.5);
scaleup=(3/2)/2; // braces are what the camera pivots from. This factor a size increase ratio.  
difference() {
	union(){ // All the solids. 
           	if("P"==PO){ // Offset 
				difference (){
						rotate([0, 90,0]) {
						
								cylinder(h=length, r=size*scaleup,center=true);
						}
								cube([length*1.4, size*scaleup,size*scaleup],center=true);
								//cylinder(h=length*2, r=size/2,center=true);
							
						}
			} else {
				translate([cylwidth/4,0,0])
				difference (){
						rotate([0, 90,0])	
								cylinder(h=length-(cylwidth)+wall, r=size*scaleup,center=true);
						cube([length*1.4,size*scaleup,size*scaleup],center=true);
				}
			}    

        		for (direction = [1, -1])  {
             	translate([direction * inner_spar_offset, 0, 0 ]) {
					cylinder(h=1.5*size, r=size/2, $fs=0.5);
				}

				rotate([90, 0,0]) {
					if ("P"==PO) {
							translate([direction * (inner_offset+pole+epsilon), 0,0]) 
								cylinder(h=size*1.5, r=size/2, $fs=0.5);
					} else {
							translate([(direction*inner_soffset)+(pole+epsilon), 0]) 
								cylinder(h=size*1.5, r=size/2, $fs=0.5);
					}
						
				} // rotate
         	} //for
		
			if ("P"==PO) {
        			//washer on the outside
					rotate([90,0,00])
						translate([0,0,-(size*3/2)/2])
						cylinder(h=(washer_height+wall),r=size/2);
				}
	} //union

	union(){ // all the holes.
        		for (direction = [1, -1])  {
             	translate([direction * inner_spar_offset, 0, size*-scaleup])  {
                 	cylinder(h=size*4, r=zip/2, $fs=0.5,center=true);
                     translate([0,0,wall  ])
                     	cylinder(h=(size*9), r=(pole)/2, $fs=0.5);
                 }
                	rotate([90, 0,0]) {
					if("P"==PO) {
                     	translate([direction * (inner_spar_offset+pole), 0,size/2]) {
                         		union() {
                         			cylinder(h=size*4, r=zip/2,center=true, $fs=0.5);
                              	translate([0,0,wall ])
                               		cylinder(h=(size*2.5), r=(pole)/2, center=true , $fs=0.5);
                         		}
                         	}//translate
					} else {
							translate([(direction*inner_spar_offset)+(pole+epsilon), 0,size/2]) {
								cylinder(h=size*4, r=zip/2,center=true, $fs=0.5);
								translate([0,0,wall ])
                                      	cylinder(h=(size*2.5), r=(pole)/2, center=true , $fs=0.5);
                             	}
					}//if 
				}//rotate
             // bolt hole


			cylinder(h=size*9,r=bolt_diameter/2,$fs=0.5,center=true);                   
            } //for
	} //union

        
	if ("P"==PO) { // 
     	rotate([-90, 0,0])
        		translate([0,0,-(size)/2])
              	cylinder(h=size*9,r=bolt_diameter/2,$fs=0.5,center=true);
		}
 } //difference
} //module



/// This is a big circule with circles drilled through it at the same spacing as the pipebrace.  
// Probably too heavy to fly, but makes an ok jig if you are drilling dowels.
// remember that this part is  polarized if Offset is chosen
// This has 2 inner poles & 2  outer poles. 	
// dowel is diameter of aluminum tube to be slotted through the large middle hole. 
module braceJig(PO, inner_offset, pole, bolt_diameter,zip,dowel)
{
  length = 2*inner_offset+(cylwidth*2.5);

  difference() {

			rotate([0, 90,0]) {
				difference (){
					cylinder(h=length,r=(dowel+4*wall)/2, center=true);
					cylinder(h=length,r=dowel/2, center=true);
				}
			}
  	

	union(){ // all the holes. 
    	for (direction = [1, -1])  {
     		union(){	
					// standard cylinders for spars
        			translate([direction * inner_offset, 0, -dowel])  {
						cylinder(h=5*dowel, r=zip/2, $fs=0.5, center=true);
						translate([0,0,wall+epsilon ]) 
							cylinder(h=(dowel+3*wall), r=(pole)/2, $fs=0.5);
					}

				rotate([90, 0,0]) {
					// put holes in for spar holders. 
					if ("P"==PO) {// parallel spar holders
							translate([direction * (inner_offset + pole), 0,(wall+epsilon)-size/2]) {
							union() {
								cylinder(h=size*4, r=zip/2,center=true, $fs=0.5);
								translate([direction*epsilon,0,-dowel/2+epsilon]) // avoid intersecting differences that create holes in space tiem. 
									cylinder(h=(dowel+4*wall), r=(pole)/2, $fs=0.5);
							}
						} //translate
					} else { 
						translate([ (direction *inner_offset)+pole, 0,(wall)-size/2]) {
								union() {
									cylinder(h=size*4, r=zip/2,center=true, $fs=0.5);
									translate([direction*epsilon,0,-dowel/2]) // avoid intersecting differences that create holes in space time. 
										cylinder(h=(dowel+4*wall), r=(pole)/2, $fs=0.5);
								}
							}
					} //endiff
				}
			}
	   		
		} //for
  	} //union

 	// wire chase hole
		translate([0,0,-(size)/2])
	 		cylinder(h=dowel*3,r=bolt_diameter/2,center=true,$fs=0.5);
			rotate([90, 0,0]) 
				cylinder(h=dowel*3,r=bolt_diameter/2,center=true,$fs=0.5);
 } //difference
} //module
  



// half of a hinge parallel to the shafts. 
module hinge_pintle(LR,inner_offset, pole, bolt_d,zip) 
{
  length = 2*inner_offset+pole+2*wall;
  pintle_height=washerH*1.1; // remove one bearing surface? 

  difference() {
	
	union(){
		cube([length, size, size], center=true);
    		for (direction = [1, -1])  {
        		translate([direction * inner_offset, 0, (size*1/2)-wall])  
				cylinder(h=size+wall, r2=(spar_diameter+wall)/2,r1=size/2, $fs=0.5);
		} //for
	// pintle /washer location. 
 	 	rotate([-90*LR, 0,0]) 
			translate([0,0,size/2])
	 			cylinder(h=pintle_height,r=washerD,$fs=0.5);
  	} //union

	union(){
    		for (direction = [1, -1])  {
			//TODO: pass in variable picking one. 
      		union(){ // zip holes on the brace/ bottom
        			translate([direction * inner_offset, 0, 0])  {
					cylinder(h=(size*2)-wall, r=(spar_diameter)/2, $fs=0.5);
					cylinder(h=size*2, r=zip/2,center=true, $fs=0.5);
        			}
      		}
			*union(){ // zip holes on the cones/top
        			translate([direction * inner_offset, 0, 0])  {
					cylinder(h=size*3, r=zip/2,center=true, $fs=0.5);
					translate([0,0,-2*wall])
						cylinder(h=((size*2)-wall), r=(spar_diameter)/2, $fs=0.5);
        			}
      		}
		} //for
  	} //union

 	// bolt hole
 	 rotate([-90*LR, 0,0]) 
		translate([0,0,-(size)/2])
	 		cylinder(h=size*3,r=bolt_d/2,center=true,$fs=0.5);
 } //difference
} //module		
	
// other half of a hinge parallel to the shafts.	
module hinge_gudgeon(LR,inner_offset, pole, bolt_d,zip) 
// assumes that you want the pivot diameter to be WasherD
{
  length = 2*inner_offset+pole+2*wall;

  difference() {
	
	union(){
		cube([length, size, size], center=true);
    		for (direction = [1, -1])  {
        		translate([direction * inner_offset, 0, (size*1/2)-wall])  
				cylinder(h=size+wall, r2=(spar_diameter+wall+fudge)/2,r1=size/2, $fs=0.5);
		} //for
		// gudgeon wrapper hole 
 	 		rotate([-90*LR, 0,0]) 
				translate([0,0,(size/2)-washerH])
	 				cylinder(h=washerH*2,r=washerD+wall,$fs=0.5);
  	} //union

	union(){
    		for (direction = [1, -1])  {
			//TODO: pass in variable picking one. 
      		union(){ // zip holes on the brace/ bottom
        			translate([direction * inner_offset, 0, 0])  {
					cylinder(h=(size*2)-wall, r=(spar_diameter)/2, $fs=0.5);
					cylinder(h=size*2, r=zip/2,center=true, $fs=0.5);
        			}
      		}
			*union(){ // zip holes on the cones/top
        			translate([direction * inner_offset, 0, 0])  {
					cylinder(h=size*3, r=zip/2,center=true, $fs=0.5);
					translate([0,0,-2*wall])
						cylinder(h=((size*2)-wall), r=(spar_diameter)/2, $fs=0.5);
        			}
			}
      	
		} //for
  	} //union
	// pintle hole 
 	 rotate([-90*LR, 0,0]) {
		union(){
			translate([0,0,size-washerH])
	 				cylinder(h=washerH*2,r=washerD+fudge,$fs=0.5);
 			// bolt hole
			translate([0,0,-(size)/2])
	 			cylinder(h=3*size,r=bolt_d/2,$fs=0.5);
		}
	}
 } //difference
} //module		



//// Bond a gear to a TiltPivot, suitable for the Pitch servo. 
// distance between gear axles is assumed to be 3 cm
module GearedTiltPivot(offset,shaft_d,bolt_d,gear_bushing_height,do_plate_not_poles,plate_w,plate_h) {
 length =  4*wall+ washerD; // How wide should the part be along the long spar axis?
  washer_cyl=gear_bushing_height+size/2; // bushing height from base.
  // gear ratio set here. 
  load_teeth = 21; servo_teeth = 19;
   p = fit_spur_gears(load_teeth, servo_teeth, 30);

difference(){
	union(){ // solids. 
		gear (circular_pitch=p,
			gear_thickness = 2.5,
			rim_thickness = 6,
			rim_width=4,
			hub_thickness = 6+(size/2), //  (4.5+3), //servo height+rim_thickness 
			hub_diameter=2*size,
	   	 	number_of_teeth = load_teeth,
			bore_diameter=bolt_d,
			circles=0);

	rotate([-90,00,00]){
		translate([0,-3.01-(shaft_d+gear_bushing_height),0])
			BracePivot(inner_spar_offset,spar_diameter,bolt_d+fudge,gear_bushing_height,do_plate_not_poles,plate_w,plate_h );
		}
 	}
	translate([-60,10,0]){
		*cube([100,100,100]); // uncomment remove bottom half of gear
	}	
  }
	//servo side. 
	translate([gear_outer_radius(load_teeth, p) + gear_outer_radius(servo_teeth+2, p),0,0])
	gear (circular_pitch=p,
		gear_thickness = 4,
		rim_thickness = 4,
		hub_thickness = 3,
		hub_diameter=10,
		circles=16,
		number_of_teeth = servo_teeth,
		bore_diameter=5.8,// Bug ::: hard coded ::: outer diameter of tiny servo horns,+fudge
		rim_width = 2
		);

}



// create a mounting plate for a camera with the camera screw offset by camera_offset from the pivot point. 
// camera bolt is assumed to be .25 inches. 
module DirectCameraPivot(offset,shaft_d,bolt_d,gear_bushing_height,camera_offset) {
	
load_teeth = 21; servo_teeth = 19;
gear_rim_thickness=6;
bolt_head_width=11; // making stupid assumption both bolts are the same. 
bolt_head_height=5;
elevation=1.5*size;// how tall should mount be above gear. Increase when bolt heads are close or pivot bolt is larger diameter.
p = fit_spur_gears(load_teeth, servo_teeth, 30);

	// part opposite servo
	difference(){
		union(){
			gear (circular_pitch=p,
				gear_thickness = 2.5,
				rim_thickness = gear_rim_thickness,
				rim_width=8,
				hub_thickness = 12, //  (4.5+3), //servo height+rim_thickness 
				hub_diameter=2.4*size,
	   	 		number_of_teeth = load_teeth,
				bore_diameter=bolt_d,
				circles=0);

			rotate([-90,00,00]){ // unique BracePivot thing for holding camera
				translate([0,-size*.75-gear_rim_thickness,0]) {
					difference() {
						union(){
							hull() {
								cube([size*1.5, size*1.5, elevation], center=true);
								for (direction = [1, -1])  {
			     		   			translate([direction * camera_offset,-size/2, 0 ])  {
					   					cube([(camera_bolt_d+4*wall),size/2,elevation*.75],center=true);	
									}	
								}
							}
							rotate([-90, 0,0])  
								translate([camera_offset,0,gear_rim_thickness/2]) // center of mass offset
									cylinder(h=(size*1.5),r=(bolt_head_width)/2,center=true,$fs=0.5);
						} //union
						// pivot bolt hole & recess
			 	 			rotate([-90, 0,0])  {
				 				cylinder(h=size*5,r=bolt_d/2,center=true,$fs=0.5);
								translate([0,0,-.75*size]) 
									hexagon(bolt_head_width+1,bolt_head_height*1.2);
	
								}
					
		 			}// difference
				} // translate
			} // rotate
		} // union of shape. 	

		translate([camera_offset,0,0]) { // center of mass offset
			cylinder(h=size*9,r=camera_bolt_d/2,center=true,$fs=0.5);
			translate([0,0,0]) {
				cylinder(h=gear_rim_thickness*2.5,r=(bolt_head_width+1)/2,center=true);
			}
  		}
	} //  end hinge side contraption


	//servo mounted gear. 
	translate([gear_outer_radius(load_teeth, p) + gear_outer_radius(servo_teeth+2, p),0,0])
		gear (circular_pitch=p,
			gear_thickness = 4,
			rim_thickness = 4,
			hub_thickness = 3,
			hub_diameter=10,
			circles=12,
			number_of_teeth = servo_teeth,
			bore_diameter=5.8,// Bug ::: hard coded ::: outer diameter of tiny servo horns,+fudge
			rim_width = 2
			);

}



// Pan Gear pair.
module pan_gears(gear_spacing_in_mm, free_gear_bolt,servo_gear_bolt) {
	n1 = 14; n2 = 59; //1:.237
	p = fit_spur_gears(n1, n2, gear_spacing_in_mm);
	// Simple Test:
	gear (circular_pitch=p,
		gear_thickness = 5,
		rim_thickness = 6, 
		rim_width=2,
		hub_thickness = 8, // taller hub makes tapping easier.
		hub_diameter=12,
	    number_of_teeth = n1,
		bore_diameter=free_gear_bolt,
		circles=9);

	translate([0,20,0]) // print a spare driven gear, tapping is hard, you can always make the gear taller. 
		gear (circular_pitch=p,
			gear_thickness = 5,
			rim_thickness = 6, 
			rim_width=2,
			hub_thickness = 8, // taller hub makes tapping easier.
			hub_diameter=12,
		    number_of_teeth = n1,
			bore_diameter=free_gear_bolt,
			circles=9);
	
	translate([gear_outer_radius(n1, p) + gear_outer_radius(n2, p)+2,0,0]) {
		gear (circular_pitch=p,
			gear_thickness = 2,
			rim_thickness = 4,
			hub_thickness = 4,
			hub_diameter=12,
			circles=24,
			number_of_teeth = n2,
			bore_diameter=servo_gear_bolt, //5.6+.3,// outer diameter of tiny servo horns
			rim_width = 2
			);

		}
	
}

module tilt_gears(gear_spacing_in_mm, free_gear_bolt,servo_gear_bolt) {
	n1 = 21; n2 = 19; // we want 90degrees of tilt and a tiny bit of mechanical advantage. this gives 1.1 advantage + 90+10degrees each side of tilt. 
	p = fit_spur_gears(n1, n2, gear_spacing_in_mm);
	// Simple Test:
	gear (circular_pitch=p,
		gear_thickness = 3,
		rim_thickness = 3,
		rim_width=4,
		hub_thickness = 4,
		hub_diameter=12,
	    number_of_teeth = n1,
		bore_diameter=free_gear_bolt,
		circles=12);
	
	translate([gear_outer_radius(n1, p) + gear_outer_radius(n2, p),0,0])
	gear (circular_pitch=p,
		gear_thickness = 3,
		rim_thickness = 5,
		hub_thickness = 3,
		hub_diameter=10,
		circles=12,
		number_of_teeth = n2,
		bore_diameter=servo_gear_bolt,// outer diameter of tiny servo horns
		rim_width = 2
		);
}



	////// test allignment of all primatives. 
//// MAIN 
shellsize=cylwidth;// make cross spars same height/depth as spar+ wall. 

fudge=.4; // size to increase all hole diameters to deal with shrinkage. 
// Do the two pan corners

//module pipebrace(OP, inner_offset, pole, washer_height,bolt_diameter,zip)


*translate([30,30,0]){
	mirror([0,1,0]) {
		pipebrace("P",inner_spar_offset,spar_diameter,0.250,3.5+fudge,zip+fudge);
	}
}



*translate ([0,0,(8+2*wall)]) {
		braceJig("P",inner_spar_offset,spar_diameter,0.25*inchmm,zip+fudge,16);
	translate ([06,-30,0]) {
		mirror([0,1,0]) {// Remember this if printing O
			braceJig("P",inner_spar_offset,spar_diameter,0.25*inchmm,zip+fudge,16);
		}
	}
}

*translate([00,10 ,0])
//module offset_pipebrace(LR, inner_offset, pole, washer_height,bolt_diameter,zip)
	//mirror([0,1,0]) 
		pipebrace("P",inner_spar_offset,spar_diameter,1,2+fudge,zip+fudge);

// throw in a pivot for the side opposite the servo & gear. 
//(LR,inner_offset, pole, bolt_d,zip)
* translate([0,-2*shellsize ,(size/2) -wall])
	rotate([90,00,0])
		hinge_gudgeon(1,inner_spar_offset,spar_diameter,3.5,zip+fudge);

* translate([0,-4.5*shellsize,size/2 +wall])
	rotate([0,00,0])
		hinge_pintle(1,inner_spar_offset,spar_diameter,3.5,zip+fudge);


*translate ([45,-40,00]){
	rotate([90,0,0]){
// do the inner, tilt servo and pivot. 		
		ServoHolder( inner_spar_offset, spar_diameter,do_servo_lightening);
		translate([00,0,-30])
			BracePivot(inner_spar_offset,spar_diameter,3.5+fudge,washerH,do_plate_not_poles,plate_thickness );
		}
}

*translate([0,9,spar_diameter/2+wall/2]){
// do the outer, pan servo and pivot. 		
	rotate([90,0,0]) {
		ServoHolder( outer_spar_offset, spar_diameter,do_servo_lightening);
		translate([0,wall/2,wall-30])
			BracePivot(outer_spar_offset,spar_diameter,pivot_bolt+fudge,washerH,0,plate_width, plate_height );
		}
}


*translate([00,0,(size/2)+wall])
// For holding Al Camera plate
	BracePivot(inner_spar_offset,spar_diameter,inchmm/8 ,0,"V",inchmm*3/4,plate_height );
		
// other brace
*translate([0,-20,(size/2)+wall])
// For holding Al Camera plate
	BracePivot(inner_spar_offset,spar_diameter,inchmm/8 ,0,"V",inchmm*3/4,plate_height );
		

*translate([50,wall/2,wall-30])
		BracePivot(inner_spar_offset,spar_diameter,pivot_bolt+fudge,0,do_plate,plate_width,plate_height );


//// Build the pivot parts. 
//Tilt
*rotate([0,0,90])
	translate([10,-45,0])
		GearedTiltPivot(inner_spar_offset,spar_diameter,pivot_bolt+fudge,1/2,"H",plate_width,plate_height );

// Direct camera pivot
*translate([-40,0,(size+wall)/2])
	rotate([90,0,0])
		BracePivot(inner_spar_offset,spar_diameter,pivot_bolt,washerH,0,0,0 );

*DirectCameraPivot(inner_spar_offset,spar_diameter,pivot_bolt,3,cam_offset) 

*rotate([90,0,0]){
// do the inner, tilt servo and pivot. 	
		translate([00,size/2+wall/2,-50])
			BracePivot(inner_spar_offset,spar_diameter,(inchmm/4)+fudge,washerH,"V",0,0 ); // switched to V because lightening is too extreme
		}


*translate ([00,-60,(wall+spar_diameter)/2]){
	rotate([90,0,0]){
// do the inner, tilt servo and pivot. 		
		*ServoHolder( inner_spar_offset, spar_diameter,do_servo_lightening);
		translate([00,+wall/2,-30])
			BracePivot(inner_spar_offset,spar_diameter,2.5+fudge,washerH,"0",3 );
		}
}


*translate([-spar_diameter,0,0]){
	rotate([-90,0,0])
		CameraPlate(outer_spar_offset,spar_diameter,20+fudge);
}


// Pan gears
translate([-40,-50,0]) {
	pan_gears(35,pivot_bolt,5.9); // 3rd arg is roughly roughly size of outer diameter of Hitec tiny servo. Size that way to make drilling holes easier. 
}

// Tilt gears
*translate([20,40,0])
	tilt_gears(35,pivot_bolt,5.9);
