// UNIVAC IX Smart Farm Mechanical Layer: Weatherproof Bolt-Down Lid
// Integrates an inverted compression ridge and panels for circular twist-lock connectors

$fn = 60;
box_w = 110;
box_l = 150;
wall_t = 4;
gasket_w = 2.6; // Slightly narrower than groove for dynamic friction fit
gasket_h = 3.5; // Extrudes down into the base track

module bolt_down_lid() {
    union() {
        // Main structural top plate
        difference() {
            cube([box_l + (wall_t * 2), box_w + (wall_t * 2), wall_t], center=true);
            
            // 4x Perimeter structural bolt clearance channels (M5 clear)
            for(x = [-(box_l/2) - 2, (box_l/2) + 2]) {
                for(y = [-(box_w/2) - 2, (box_w/2) + 2]) {
                    translate([x, y, 0]) cylinder(h=wall_t + 2, r=2.7, center=true);
                }
            }
            
            // Cutouts for Flush-Mounted Circular Twist-Lock Connectors (e.g., Amphenol/MIL-SPEC)
            translate([-35, 0, 0]) cylinder(h=wall_t + 2, r=12.2, center=true); // Main Twist-Lock Bus A
            translate([35, 0, 0]) cylinder(h=wall_t + 2, r=12.2, center=true);  // Main Twist-Lock Bus B
        }
        
        // Inverted Compression Ridge (Extrudes downwards into the base groove)
        translate([0, 0, -(wall_t/2) - (gasket_h/2)]) {
            difference() {
                cube([box_l + gasket_w, box_w + gasket_w, gasket_h], center=true);
                cube([box_l - gasket_w, box_w - gasket_w, gasket_h + 1], center=true);
            }
        }
    }
}

// Render the top enclosure lid interface
color("DimGray") bolt_down_lid();
