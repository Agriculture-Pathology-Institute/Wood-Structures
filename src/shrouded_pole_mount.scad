// ===================================================================================
// UNIVAC IX Smart Farm Mechanical Layer: Shrouded Pole-Clamp Bracket Assembly
// Integrates 45° Washdown Canopy, V-Block Post Alignment, and Banding Slots
// ===================================================================================

$fn = 80;

// Enclosure footprint alignment matching metrics
box_l = 150;
box_w = 110;
box_h = 50;            // Physical height profile of the sealed chassis box
wall_t = 6;            // Increased wall thickness for industrial strapping tension
standoff_h = 8;        // Vent airflow separation gap
stud_width = 50.8;     // 2-inch rough-sawn dimensional timber channel

module shrouded_pole_mount() {
    union() {
        difference() {
            union() {
                // 1. Main Heavy-Duty Structural Adapter Base Plate
                cube([box_l + 40, box_w + 16, wall_t], center=true);
                
                // 2. Backside V-Block Alignment Cradle (Locks onto round poles/pipes)
                translate([0, 0, -(wall_t/2) - 10])
                    difference() {
                        cube([box_l + 40, 45, 20], center=true);
                        // 120-Degree V-Groove alignment notch extrusion
                        rotate([45, 0, 0]) cube([box_l + 50, 35, 35], center=true);
                    }
                
                // 3. 4x Enclosure Airflow Ventilation Standoffs
                for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
                    for(y = [-35, 35]) {
                        translate([x, y, (wall_t/2) + (standoff_h/2)])
                            cylinder(h=standoff_h, r=10, center=true);
                    }
                }
            }
            
            // --- VERTICAL POLE-WRAP CLAMPING SLOTS (For 3/4" Industrial Steel Banding) ---
            // Dual upper and lower pass-through channels cut deep across the V-block core
            for (y_offset = [-38, 38]) {
                translate([0, y_offset, -(wall_t/2) - 5])
                    cube([box_l + 10, 6, 22], center=true);
            }
            
            // --- ENCLOSURE MACHINE THREAD HOLES (4x M6 Captive Nut Recesses) ---
            for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
                for(y = [-35, 35]) {
                    translate([x, y, 0]) cylinder(h=40, r=3.2, center=true);
                    translate([x, y, -(wall_t/2) - 1]) cylinder(h=3, r=6.0, center=true, $fn=6);
                }
            }
            
            // --- HEAVY TIMBER SCREW ANCHOR SLOTS (Backup Flat Timber Mounting Option) ---
            for(x = [-(box_l/2) - 15, (box_l/2) + 15]) {
                for(y = [-(box_w/2) - 2, (box_w/2) + 2]) {
                    translate([x, y, 0]) cylinder(h=40, r=4.5, center=true);
                    translate([x, y, (wall_t/2) + 5]) cylinder(h=10, r=9.0, center=true);
                }
            }
            
            // --- HYDROPHOBIC VENT BREATHER AIR OUTLET HOLE ---
            translate() cylinder(h=60, r=18, center=true);
        }
        
        // --------------------------------===========================================
        // INTEGRATED WEATHER SHROUD (Shed Roof Canopy Architecture)
        // --------------------------------================================-----------
        translate([0, (box_w/2) + 8, (wall_t/2)]) {
            difference() {
                union() {
                    // 45-Degree Sloped Deflection Roof Panel
                    rotate()
                        translate([0, -((box_w + 35)/2), wall_t/2])
                            cube([box_l + 40, box_w + 35, wall_t], center=true);
                    
                    // Left Triangular Splash Guard & Gusset Wall
                    translate([-(box_l/2) - 20, 0, 0])
                        rotate([0, -90, 0])
                            linear_extrude(height=wall_t)
                                polygon(points=[, [0,-(box_w+30)], [(box_h+30),0]]);
                                
                    // Right Triangular Splash Guard & Gusset Wall
                    translate([(box_l/2) + 20 + wall_t, 0, 0])
                        rotate([0, -90, 0])
                            linear_extrude(height=wall_t)
                                polygon(points=[, [0,-(box_w+30)], [(box_h+30),0]]);
                }
                // Trim roof tail overlap to clear the flat pole mounting boundary
                translate() cube([box_l + 50, 100, 200], center=true);
            }
        }
    }
}

// Render structural multi-mount environmental assembly
color("SaddleBrown") shrouded_pole_mount();
