// UNIVAC IX Smart Farm Mechanical Device: Weatherproof Controller Chassis
// Integrates an environmental seal groove and watertight gland openings

$fn = 60;
box_w = 110;
box_l = 150;
box_h = 50;
wall_t = 4;
gasket_w = 3;
gasket_d = 2.5;

module weatherproof_base_housing() {
    difference() {
        // Main external body block
        cube([box_l + (wall_t*2), box_w + (wall_t*2), box_h], center=true);
        
        // Internal component void
        translate([0, 0, wall_t]) 
            cube([box_l, box_w, box_h], center=true);
            
        // Tongue-and-Groove Environmental Gasket Track along the top rim
        translate([0, 0, (box_h/2) - (gasket_d/2)])
            difference() {
                cube([box_l + (gasket_w), box_w + (gasket_w), gasket_d + 1], center=true);
                cube([box_l - (gasket_w), box_w - (gasket_w), gasket_d + 3], center=true);
            }
            
        // Watertight PG9 / PG11 Cable Gland Entry Ports (Side walls)
        translate([(box_l/2) + wall_t, -25, -10]) rotate([0, 90, 0]) cylinder(h=20, r=8.1, center=true); // Port A
        translate([(box_l/2) + wall_t, 25, -10]) rotate([0, 90, 0]) cylinder(h=20, r=8.1, center=true);  // Port B
    }
}

module heavy_wood_mounting_tabs() {
    // Structural exterior tabs to screw the sealed unit directly into wooden framing
    for (x = [-(box_l/2)-12, (box_l/2)+12]) {
        for (y = [-35, 35]) {
            translate([x, y, -(box_h/2) + 3]) {
                difference() {
                    cube([16, 16, 6], center=true);
                    cylinder(h=10, r=3.5, center=true); // Timber fastener hole
                }
            }
        }
    }
}

// Render the environmental assembly
color("Charcoal") weatherproof_base_housing();
color("DarkSienna") heavy_wood_mounting_tabs();
