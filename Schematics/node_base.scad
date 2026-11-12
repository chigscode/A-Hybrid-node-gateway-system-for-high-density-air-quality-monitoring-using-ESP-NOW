//======================================================
// LOW PROFILE NODE 1 ENCLOSURE - BASE ONLY
// WITH:
// - DUAL-SIDE SENSOR VENTS
// - POWER SECTION: BATTERY + BUCK CONVERTER + CASING SWITCH
// - CORNER SCREW MOUNT PILLARS
//======================================================

//======================================================
// BOX SETTINGS
//======================================================
wall = 3;
floor = 3;

box_length = 170;
box_width  = 120;
box_height = 35;

corner = 5;

//======================================================
// MAIN BOX
//======================================================
difference() {

    // OUTER BODY
    roundedBox(box_length, box_width, box_height, corner);

    // INNER HOLLOW
    translate([wall, wall, floor])
    roundedBox(
        box_length - wall*2,
        box_width - wall*2,
        box_height,
        corner-1
    );

    //--------------------------------------------------
    // USB PORT
    //--------------------------------------------------
    translate([-1, 50, 10])
    cube([6, 14, 8]);

    //--------------------------------------------------
    // SWITCH OPENING (Positioned between battery & buck)
    //--------------------------------------------------
    translate([box_length-2, 33, 10])
    cube([6, 12, 6]);

    //--------------------------------------------------
    // POWER JACK
    //--------------------------------------------------
    translate([box_length-2, 45, 10])
    cube([6, 10, 10]);

    //======================================================
    // SENSOR VENTS
    //======================================================

    // MQ135 Ventilation (Rear Wall)
    for(x=[0:5])
    for(y=[0:5])
    translate([130 + x*5, box_width+1, 10 + y*4])
    rotate([90,0,0])
    cylinder(h=5, d=3, $fn=20);

    // MQ135 Ventilation (Front Wall)
    for(x=[0:5])
    for(y=[0:5])
    translate([130 + x*5, -1, 10 + y*4])
    rotate([90,0,0])
    cylinder(h=5, d=3, $fn=20);

    // DHT11 Ventilation (Rear Wall)
    for(x=[0:4])
    for(y=[0:4])
    translate([136 + x*4, box_width+1, 55 + y*4])
    rotate([90,0,0])
    cylinder(h=5, d=2, $fn=20);

    // Buzzer Holes (Rear Wall)
    for(x=[0:4])
    for(y=[0:4])
    translate([140 + x*4, box_width+1, 85 + y*4])
    rotate([90,0,0])
    cylinder(h=5, d=2, $fn=20);
}

//======================================================
// SCREW MOUNT PILLARS (Added to Base Corners)
//======================================================
module screw_pillar() {
    difference() {
        cylinder(h=box_height-floor, d=8, $fn=30);
        translate([0,0,-1]) cylinder(h=box_height, d=2.8, $fn=30); // Hole for M3 screw
    }
}

translate([wall+4, wall+4, floor]) screw_pillar();
translate([box_length-wall-4, wall+4, floor]) screw_pillar();
translate([wall+4, box_width-wall-4, floor]) screw_pillar();
translate([box_length-wall-4, box_width-wall-4, floor]) screw_pillar();

//======================================================
// INTERNAL COMPARTMENTS
//======================================================

//------------------------------------------------------
// POWER SUPPLY AREA
//------------------------------------------------------

// Divider Wall
translate([40,5,3])
cube([3,110,25]);

// Battery Holder Slot (Pushed back)
translate([8,45,3])
cube([28,55,2]);

// Buck Converter Slot (Added in front of battery)
translate([8,10,3])
cube([28,25,2]);

//------------------------------------------------------
// MAIN PCB AREA
//------------------------------------------------------

// PCB Base
translate([43,5,3])
cube([80,110,2]);

// PCB POSTS
translate([50,15,3]) pcb_post();
translate([115,15,3]) pcb_post();
translate([50,95,3]) pcb_post();
translate([115,95,3]) pcb_post();

// ESP32 Platform
translate([60,35,3])
cube([45,25,2]);

//------------------------------------------------------
// LCD SUPPORTS (Moved next to MQ135 Area)
//------------------------------------------------------

// LCD Mount Platform
translate([55,5,3])
cube([70,10,5]);

// LCD Posts
translate([58,8,3]) pcb_post();
translate([120,8,3]) pcb_post();

//------------------------------------------------------
// SENSOR AREA
//------------------------------------------------------

// Divider Wall
translate([123,5,3])
cube([3,110,25]);

// MQ135 HOLDER
translate([132,15,3])
cube([28,28,3]);

// DHT11 HOLDER
translate([136,55,3])
cube([20,18,3]);

// BUZZER HOLDER
translate([145,90,3])
cylinder(h=3,d=18,$fn=40);

//------------------------------------------------------
// LED HOLDERS (Moved side-by-side next to LCD)
//------------------------------------------------------

// GREEN LED HOLDER
translate([40,8,3])
cylinder(h=4,d=6,$fn=40);

// RED LED HOLDER
translate([130,8,3])
cylinder(h=4,d=6,$fn=40);

//======================================================
// MODULES
//======================================================

module roundedBox(l,w,h,r){
    hull(){
        translate([r,r,0])     cylinder(r=r,h=h,$fn=40);
        translate([l-r,r,0])   cylinder(r=r,h=h,$fn=40);
        translate([r,w-r,0])   cylinder(r=r,h=h,$fn=40);
        translate([l-r,w-r,0]) cylinder(r=r,h=h,$fn=40);
    }
}

module pcb_post(){
    difference(){
        cylinder(h=6,d=8,$fn=30);
        translate([0,0,-1])
        cylinder(h=8,d=3,$fn=30);
    }
}
