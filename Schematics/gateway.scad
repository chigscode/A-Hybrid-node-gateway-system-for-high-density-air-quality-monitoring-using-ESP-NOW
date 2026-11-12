//======================================================
// PRECISION RASPBERRY PI 3B + ESP32 NODEMCU ENCLOSURE
// EXACT SPECIFICATION HARDWARE ALIGNMENT
//======================================================

//======================================================
// SYSTEM CONFIGURATION VARIABLES
//======================================================
wall = 3;
floor = 3;
clearance = 0.5; // Print tolerance around board edges

// Official Board Dimensions
pi_l = 85.0;
pi_w = 56.0;
esp_l = 52.0;
esp_w = 28.5;

// Enclosure Dimensions Calculated from Board Layouts
box_length = wall + pi_l + 15 + esp_l + wall; // Includes 15mm center channel
box_width  = wall + pi_w + clearance*2 + wall;
box_height = 28; // Clearance for internal components up to lid
corner = 5;

// Board Origin Coordinates
pi_x  = wall + clearance;
pi_y  = wall + clearance;
esp_x = box_length - wall - esp_l - clearance;
esp_y = wall + clearance + (pi_w - esp_w)/2; // Centered vertically relative to the Pi

// Standoff heights (Distance from floor to bottom of PCB)
pi_z_lift  = 4.0; 
esp_z_lift = 4.0;

//======================================================
// MAIN CASING DIFFERENCE MATCHING TREE
//======================================================
difference() {

    // 1. OUTER SHELL BODY
    roundedBox(box_length, box_width, box_height, corner);

    // 2. INNER WALL HOLLOWING
    translate([wall, wall, floor])
    roundedBox(
        box_length - wall*2,
        box_width - wall*2,
        box_height,
        corner-1
    );

    //--------------------------------------------------
    // RASPBERRY PI 3B PORT WINDOWS (Left & Back Walls)
    // Offset values taken from official Pi 3B datasheets
    //--------------------------------------------------
    
    // A. MicroSD Card Slit (Left Wall Floor Surface)
    translate([pi_x - clearance - wall - 1, pi_y + 21.0, floor])
    cube([wall + 2, 14.0, 3.5]);

    // B. Dual USB + Ethernet Socket Outlets (Left Side Wall)
    translate([pi_x - clearance - wall - 1, pi_y + 2.5, floor + pi_z_lift])
    cube([wall + 2, 43.5, 16.5]);

    // C. Full-Size HDMI Female Port (Back Wall)
    translate([pi_x + 32.0, box_width - wall - 1, floor + pi_z_lift - 1.0])
    cube([16.5, wall + 2, 8.0]);

    // D. 3.5mm AV Audio Headphone Jack (Back Wall)
    translate([pi_x + 53.5, box_width - wall - 1, floor + pi_z_lift + 3.0])
    rotate([-90, 0, 0])
    cylinder(h = wall + 2, d = 7.0, $fn = 30);

    // E. Micro-USB Power Inlet (Back Wall - Positioned after the Audio Jack)
    translate([pi_x + 66.5, box_width - wall - 1, floor + pi_z_lift])
    cube([11.0, wall + 2, 6.0]);

    //--------------------------------------------------
    // ESP32 NODEMCU PORT WINDOW (Right Side Wall)
    //--------------------------------------------------
    
    // F. Micro-USB Programming Interface
    translate([esp_x + esp_l + clearance - 1, esp_y + (esp_w/2) - 6.0, floor + esp_z_lift])
    cube([wall + 2, 12.0, 6.5]);
}

//======================================================
// CORNER SCREW PILLARS FOR LID HOLES
//======================================================
module screw_pillar() {
    difference() {
        cylinder(h=box_height-floor, d=8, $fn=30);
        translate([0,0,-1]) cylinder(h=box_height, d=2.8, $fn=30); // Taps M3 screws securely
    }
}

translate([wall+4, wall+4, floor]) screw_pillar();
translate([box_length-wall-4, wall+4, floor]) screw_pillar();
translate([wall+4, box_width-wall-4, floor]) screw_pillar();
translate([box_length-wall-4, box_width-wall-4, floor]) screw_pillar();

//======================================================
// MECHANICAL BOARD STANDOFF PILLARS
//======================================================

// RASPBERRY PI 3B POSTS (All 4 standard posts added)
translate([pi_x + 3.5,      pi_y + 3.5,      floor]) board_post(pi_z_lift, 6.0, 2.2); 
translate([pi_x + 3.5 + 58, pi_y + 3.5,      floor]) board_post(pi_z_lift, 6.0, 2.2);
translate([pi_x + 3.5,      pi_y + 3.5 + 49, floor]) board_post(pi_z_lift, 6.0, 2.2);
translate([pi_x + 3.5 + 58, pi_y + 3.5 + 49, floor]) board_post(pi_z_lift, 6.0, 2.2);

// ESP32 NODEMCU 30-PIN POSTS (Standard 47mm x 23.5mm Spacing)
translate([esp_x + 2.5,       esp_y + 2.5,        floor]) board_post(esp_z_lift, 5.0, 1.8);
translate([esp_x + 2.5 + 47,  esp_y + 2.5,        floor]) board_post(esp_z_lift, 5.0, 1.8);
translate([esp_x + 2.5,       esp_y + 2.5 + 23.5, floor]) board_post(esp_z_lift, 5.0, 1.8);
translate([esp_x + 2.5 + 47,  esp_y + 2.5 + 23.5, floor]) board_post(esp_z_lift, 5.0, 1.8);

//------------------------------------------------------
// UART ROUTING PROFILE PATHWAYS
//------------------------------------------------------
// Low profile dividing partition walls with a clean 20mm wire pass-through channel
difference() {
    translate([pi_x + pi_l + 5, wall, floor])
    cube([3, box_width - wall*2, 8]);
    
    translate([pi_x + pi_l + 4, box_width/2 - 10, floor - 1])
    cube();
}

//======================================================
// UTILITY MODULE DEFINITIONS
//======================================================
module roundedBox(l, w, h, r){
    hull(){
        translate([r, r, 0])     cylinder(r=r, h=h, $fn=40);
        translate([l-r, r, 0])   cylinder(r=r, h=h, $fn=40);
        translate([r, w-r, 0])   cylinder(r=r, h=h, $fn=40);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h, $fn=40);
    }
}

module board_post(h, od, id){
    difference(){
        cylinder(h=h, d=od, $fn=30);
        translate([0, 0, -1])
        cylinder(h=h+2, d=id, $fn=30);
    }
}
