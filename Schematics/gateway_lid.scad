//======================================================
// DUAL ENCLOSURE - TOP COVER (LID) ONLY
// DESIGNED FOR: RASPBERRY PI 3B + ESP32 NODEMCU BASE
//======================================================

//======================================================
// BOX CONFIGURATION VARIABLES (Must exactly match base)
//======================================================
wall = 3;

// Official Board Dimensions
pi_l = 85.0;
pi_w = 56.0;
esp_l = 52.0;
esp_w = 28.5;
clearance = 0.5;

// Exact footprint from the base calculations
box_length = wall + pi_l + 15 + esp_l + wall; 
box_width  = wall + pi_w + clearance*2 + wall;
corner = 5;

//======================================================
// TOP COVER
//======================================================
difference() {

    //--------------------------------------------------
    // OUTER LID BODY
    //--------------------------------------------------
    roundedBox(box_length, box_width, 8, corner);

    //--------------------------------------------------
    // INNER LIP HOLLOWING
    //--------------------------------------------------
    translate([wall, wall, wall])
    roundedBox(
        box_length - wall*2,
        box_width - wall*2,
        8,
        corner-1
    );

    //--------------------------------------------------
    // THROUGH-HOLES FOR M3 CORNER MOUNT SCREWS
    // Exact matching spacing layout from the base pillars
    //--------------------------------------------------
    translate([wall+4, wall+4, -1])                   cylinder(h=15, d=3.2, $fn=30);
    translate([box_length-wall-4, wall+4, -1])        cylinder(h=15, d=3.2, $fn=30);
    translate([wall+4, box_width-wall-4, -1])         cylinder(h=15, d=3.2, $fn=30);
    translate([box_length-wall-4, box_width-wall-4, -1]) cylinder(h=15, d=3.2, $fn=30);

}

//======================================================
// MODULE DEFINITION
//======================================================
module roundedBox(l, w, h, r){
    hull(){
        translate([r, r, 0])     cylinder(r=r, h=h, $fn=40);
        translate([l-r, r, 0])   cylinder(r=r, h=h, $fn=40);
        translate([r, w-r, 0])   cylinder(r=r, h=h, $fn=40);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h, $fn=40);
    }
}
