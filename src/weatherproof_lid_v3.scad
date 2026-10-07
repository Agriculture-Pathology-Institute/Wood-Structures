// UNIVAC IX Smart Farm Mechanical Layer: Weatherproof 12-Pin Lid & Breather Vent
// Incorporates two 12-pin circular twist-lock panels and a hydrophobic vent recess

$fn = 60;
box_w = 110;
box_l = 150;
wall_t = 4;
gasket_w = 2.6;
gasket_h = 3.5;

module bolt_down_lid_12pin() {
    union() {
        // Main structural top plate
        difference() {
            cube([box_l + (wall_t * 2), box_w + (wall_t * 2), wall_t], center=true);
            
            // 4x Enclosure perimeter bolt channels (M5 clear)
            for(x = [-(box_l/2) - 2, (box_l/2) + 2]) {
                for(y = [-(box_w/2) - 2, (box_w/2) + 2]) {
                    translate([x, y, 0]) cylinder(h=wall_t + 2, r=2.7, center=true);
                }
            }
            
            // --- 12-PIN TWIST-LOCK CONNECTOR PORT A (Left) ---
            translate([-40, 0, 0]) {
                cylinder(h=wall_t + 2, r=14.5, center=true); // Center barrel cutout for 12-pin insert
                // 4x Flange screw holes (M3 standard layout)
                for (i = [-13.5, 13.5]) {
                    for (j = [-13.5, 13.5]) {
                        translate([i, j, 0]) cylinder(h=wall_t + 2, r=1.6, center=true);
                    }
                }
            }
            
            // --- 12-PIN TWIST-LOCK CONNECTOR PORT B (Right) ---
            translate([40, 0, 0]) {
                cylinder(h=wall_t + 2, r=14.5, center=true); // Center barrel cutout
                for (i = [-13.5, 13.5]) {
                    for (j = [-13.5, 13.5]) {
                        translate([i, j, 0]) cylinder(h=wall_t + 2, r=1.6, center=true);
                    }
                }
            }
            
            // --- HYDROPHOBIC PRESSURE EQUALIZATION VENT PORT (Center) ---
            translate([0, 0, 0]) {
                cylinder(h=wall_t + 2, r=6.1, center=true); // M12 x 1.5 threaded thread clearance hole
                // Recessed sealing seat for the vent integrated gasket
                translate([0, 0, (wall_t/2) - 1]) cylinder(h=2, r=9.5, center=true);
            }
        }
        
        // Inverted Compression Ridge (Drives directly down into base groove track)
        translate([0, 0, -(wall_t/2) - (gasket_h/2)]) {
            difference() {
                cube([box_l + gasket_w, box_w + gasket_w, gasket_h], center=true);
                cube([box_l - gasket_w, box_w - gasket_w, gasket_h + 1], center=true);
            }
        }
// Injected directly inside the difference() block of your lid module:

// --- HIGH-PRESSURE PNEUMATIC BACK-FLUSH PORT ---
translate([0, 22, 0]) { // Positioned directly offset from the center vent
    cylinder(h=wall_t + 2, r=2.5, center=true); // Core tap hole for M5 pneumatic fitting
    
    // Angled nozzle jet channel relief pointing down toward the vent face
    rotate([25, 0, 0]) 
        translate([0, -5, 0]) 
            cube([3, 12, wall_t + 4], center=true);
}
    }
}

color("DimGray") bolt_down_lid_12pin();
