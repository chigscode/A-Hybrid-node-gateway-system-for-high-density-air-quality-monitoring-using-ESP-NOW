//======================================================
// LOW PROFILE NODE 1 ENCLOSURE - TOP COVER ONLY
// WITH:
// - LCD WINDOW
// - SIDE-BY-SIDE GREEN & RED LED HOLES (RIGHT OF LCD)
// - CORNER SCREW THROUGH-HOLES
//======================================================

//======================================================
// BOX CONFIGURATION VARIABLES (Must match base)
//======================================================
wall = 3;
box_length = 170;
box_width  = 120;
corner = 5;

//======================================================
// TOP COVER
//======================================================
difference() {

    //--------------------------------------------------
    // OUTER COVER
    //--------------------------------------------------
    roundedBox(box_length, box_width, 10, corner);

    //--------------------------------------------------
    // INNER HOLLOW
    //--------------------------------------------------
    translate([wall, wall, wall])
    roundedBox(
        box_length - wall*2,
        box_width - wall*2,
        10,
        corner-1
    );

    //--------------------------------------------------
    // LCD WINDOW (Positioned next to MQ135)
    //--------------------------------------------------
    translate([50, -1, 3])
    cube([70, 6, 25]);

    //--------------------------------------------------
    // GREEN LED HOLE (Side-by-side right of LCD)
    //--------------------------------------------------
    translate([124, -1, 15])
    rotate([90, 0, 0])
    cylinder(h=6, d=5, $fn=30);

    //--------------------------------------------------
    // RED LED HOLE (Side-by-side right of Green LED)
    //--------------------------------------------------
    translate([130, -1, 15])
    rotate([90, 0, 0])
    cylinder(h=6, d=5, $fn=30);

    //--------------------------------------------------
    // THROUGH-HOLES FOR SCREWS (Lid Corners)
    //--------------------------------------------------
    translate([wall+4, wall+4, -1])                   cylinder(h=15, d=3.2, $fn=30);
    translate([box_length-wall-4, wall+4, -1])        cylinder(h=15, d=3.2, $fn=30);
    translate([wall+4, box_width-wall-4, -1])         cylinder(h=15, d=3.2, $fn=30);
    translate([box_length-wall-4, box_width-wall-4, -1]) cylinder(h=15, d=3.2, $fn=30);

}

//======================================================
// MODULE REUSE
//======================================================
module roundedBox(l, w, h, r){
    hull(){
        translate([r, r, 0])     cylinder(r=r, h=h, $fn=40);
        translate([l-r, r, 0])   cylinder(r=r, h=h, $fn=40);
        translate([r, w-r, 0])   cylinder(r=r, h=h, $fn=40);
        translate([l-r, w-r, 0]) cylinder(r=r, h=h, $fn=40);
    }
}
