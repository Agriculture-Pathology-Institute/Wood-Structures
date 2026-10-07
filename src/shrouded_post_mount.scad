// ===================================================================================
// UNIVAC IX Smart Farm Mechanical Layer: Shrouded Heavy Timber Mounting Bracket
// Features an integrated 45-degree shed roof canopy to deflect washdown spray
// ===================================================================================

$fn = 80;

// Enclosure footprint alignment matching metrics
box_l = 150;
box_w = 110;
box_h = 50;            // Physical height profile of the sealed chassis box
wall_t = 5;            // Reinforced bracket frame structural thickness
standoff_h = 8;        // Vent airflow separation gap
stud_width = 50.8;     // 2-inch rough-sawn dimensional timber channel

module shrouded_timber_mount() {
    union() {
        difference() {
            union() {
                // 1. Main Heavy-Duty Structural Adapter Base Plate
                cube([box_l + 40, box_w + 16, wall_t], center=true);
                
                // 2. 4x Enclosure Airflow Ventilation Standoffs
                for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
                    for(y = [-35, 35]) {
                        translate([x, y, (wall_t/2) + (standoff_h/2)])
                            cylinder(h=standoff_h, r=10, center=true);
                    }
                }
                
                // 3. Thick structural support ribs for heavy timber-screw torque loads
                for (x = [-(box_l/2) - 15, (box_l/2) + 15]) {
                    translate([x, 0, (wall_t/2) + 2])
                        cube([12, box_w + 10, 4], center=true);
                }
            }
            
            // --- ENCLOSURE MACHINE THREAD HOLES (4x M6 Captive Nut Recesses) ---
            for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
                for(y = [-35, 35]) {
                    translate([x, y, 0]) cylinder(h=40, r=3.2, center=true);
                    translate([x, y, -(wall_t/2) - 1]) cylinder(h=3, r=6.0, center=true, $fn=6);
                }
            }
            
            // --- HEAVY TIMBER SCREW ANCHOR SLOTS (5/16" or 8mm Ledger Screws) ---
            for(x = [-(box_l/2) - 15, (box_l/2) + 15]) {
                for(y = [-(box_w/2) - 2, (box_w/2) + 2]) {
                    translate([x, y, 0]) cylinder(h=40, r=4.5, center=true);
                    translate([x, y, (wall_t/2) + 4]) cylinder(h=10, r=9.0, center=true);
                }
            }
            
            // --- ROUGH-SAWN DIMENSIONAL LUMBER SELF-CENTERING CHANNEL ---
            translate([0, 0, -(wall_t/2)])
                cube([box_l + 50, stud_width + 1.5, wall_t], center=true);
                
            // --- HYDROPHOBIC VENT BREATHER AIR HOLE ---
            translate() cylinder(h=30, r=18, center=true);
        }
        
        // --------------------------------================---------------------------
        // INTEGRATED WEATHER SHROUD (Shed Roof Canopy Architecture)
        // --------------------------------================================-----------
        // Shift canopy to the top edge of the main mounting bracket plate
        translate([0, (box_w/2) + 8, (wall_t/2)]) {
            difference() {
                union() {
                    // 45-Degree Sloped Deflection Roof Panel
                    rotate([45, 0, 0])
                        translate([0, -((box_w + 35)/2), wall_t/2])
                            cube([box_l + 40, box_w + 35, wall_t], center=true);
                    
                    // Left Triangular Splash Guard & Gusset Wall
                    translate([-(box_l/2) - 20, 0, 0])
                        rotate([0, -90, 0])
                            linear_extrude(height=wall_t)
                                polygon(points=[[0,0], [0,-(box_w+30)], [(box_h+30),0]]);
                                
                    // Right Triangular Splash Guard & Gusset Wall
                    translate([(box_l/2) + 20 + wall_t, 0, 0])
                        rotate([0, -90, 0])
                            linear_extrude(height=wall_t)
                                polygon(points=[[0,0], [0,-(box_w+30)], [(box_h+30),0]]);
                }
                
                // Trim roof tail overlap to clear the flat timber post mounting boundary
                translate([0, 50, 0]) cube([box_l + 50, 100, 200], center=true);
            }
        }
    }
}

// Render environmental canopy adapter assembly
color("SaddleBrown") shrouded_timber_mount();
