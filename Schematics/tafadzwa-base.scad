//======================================================
// NODE 1 ENCLOSURE BASE
//======================================================

//======================================================
// SETTINGS
//======================================================

wall = 3;
floor = 3;

box_length = 170;
box_width  = 120;
box_height = 35;

lid_depth = 7;

corner = 5;

//======================================================
// MAIN BASE
//======================================================

difference() {

    //--------------------------------------------------
    // OUTER BODY
    //--------------------------------------------------

    roundedBox(box_length, box_width, box_height, corner);

    //--------------------------------------------------
    // INNER HOLLOW
    //--------------------------------------------------

    translate([wall, wall, floor])

    roundedBox(
        box_length - wall*2,
        box_width  - wall*2,
        box_height,
        corner-1
    );

    //--------------------------------------------------
    // TOP OPENING FOR LID
    //--------------------------------------------------

    translate([0,0,box_height-lid_depth])
    cube([box_length, box_width, lid_depth+2]);

    //--------------------------------------------------
    // USB PORT
    //--------------------------------------------------

    translate([-1, 50, 10])
    cube([6,14,8]);

    //--------------------------------------------------
    // SWITCH OPENING
    //--------------------------------------------------

    translate([box_length-2,20,10])
    cube([6,12,6]);

    //--------------------------------------------------
    // POWER JACK
    //--------------------------------------------------

    translate([box_length-2,45,10])
    cube([6,10,10]);
}

//======================================================
// INTERNAL COMPARTMENTS
//======================================================

// POWER SECTION
translate([40,5,3])
cube([3,110,25]);

translate([8,15,3])
cube([28,55,2]);

translate([12,75,3])
cylinder(h=5,d=12,$fn=40);

translate([28,75,3])
cylinder(h=5,d=12,$fn=40);

// PCB SECTION
translate([43,5,3])
cube([80,110,2]);

translate([50,15,3]) pcb_post();
translate([115,15,3]) pcb_post();
translate([50,95,3]) pcb_post();
translate([115,95,3]) pcb_post();

translate([60,35,3])
cube([45,25,2]);

// LCD SUPPORT
translate([55,5,3])
cube([70,10,5]);

translate([58,8,3]) pcb_post();
translate([120,8,3]) pcb_post();

// SENSOR AREA
translate([123,5,3])
cube([3,110,25]);

translate([132,15,3])
cube([28,28,3]);

translate([136,55,3])
cube([20,18,3]);

translate([145,90,3])
cylinder(h=3,d=18,$fn=40);

// LED HOLDERS
translate([40,8,3])
cylinder(h=4,d=6,$fn=40);

translate([130,8,3])
cylinder(h=4,d=6,$fn=40);

//======================================================
// SENSOR VENTS
//======================================================

// MQ135 VENTS
for(x=[0:5])
for(y=[0:5])

translate([130 + x*5, box_width+1, 10 + y*4])
rotate([90,0,0])
cylinder(h=5,d=3,$fn=20);

// DHT11 VENTS
for(x=[0:4])
for(y=[0:4])

translate([136 + x*4, box_width+1, 55 + y*4])
rotate([90,0,0])
cylinder(h=5,d=2,$fn=20);

// BUZZER VENTS
for(x=[0:4])
for(y=[0:4])

translate([140 + x*4, box_width+1, 85 + y*4])
rotate([90,0,0])
cylinder(h=5,d=2,$fn=20);

//======================================================
// MODULES
//======================================================

module roundedBox(l,w,h,r){

    hull(){

        translate([r,r,0])
        cylinder(r=r,h=h,$fn=40);

        translate([l-r,r,0])
        cylinder(r=r,h=h,$fn=40);

        translate([r,w-r,0])
        cylinder(r=r,h=h,$fn=40);

        translate([l-r,w-r,0])
        cylinder(r=r,h=h,$fn=40);
    }
}

module pcb_post(){

    difference(){

        cylinder(h=6,d=8,$fn=30);

        translate([0,0,-1])
        cylinder(h=8,d=3,$fn=30);
    }
}