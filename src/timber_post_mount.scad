// ===================================================================================
// UNIVAC IX Smart Farm Mechanical Layer: Heavy Timber Mounting Adapter Assembly
// Compatible with multi-ply LVL posts, columns, and rough-sawn dimensional studs
// ===================================================================================

$fn = 80;

// Enclosure Base footprint match metrics
box_l = 150;
box_w = 110;
wall_t = 5;            // Structural reinforcement wall thickness
standoff_h = 8;        // Atmospheric airflow separation gap for pressure vent
stud_width = 50.8;     // 2-inch rough-sawn stud width indexing reference

module heavy_timber_mount() {
    difference() {
        union() {
            // Main heavy-duty adapter base plate
            cube([box_l + 40, box_w + 16, wall_t], center=true);
            
            // 4x Enclosure mounting standoffs (creates the back ventilation air gap)
            for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
                for(y = [-35, 35]) {
                    translate([x, y, (wall_t/2) + (standoff_h/2)])
                        cylinder(h=standoff_h, r=10, center=true);
                }
            }
            
            // Heavy-duty structural support ribs for high timber-screw torque loads
            for (x = [-(box_l/2) - 15, (box_l/2) + 15]) {
                translate([x, 0, (wall_t/2) + 2])
                    cube([12, box_w + 10, 4], center=true);
            }
        }
        
        // --------------------------------================---------------------------
        // ENCLOSURE INTERFACE: 4x Machine Bolt Clearence Holes (M6 size clear)
        // --------------------------------================================-----------
        for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
            for(y = [-35, 35]) {
                // Thru-hole for attaching the weatherproof base box to the bracket
                translate([x, y, 0]) cylinder(h=40, r=3.2, center=true);
                // Hex nut captive pocket recessed underneath the bracket plate
                translate([x, y, -(wall_t/2) - 1]) cylinder(h=3, r=6.0, center=true, $fn=6);
            }
        }
        
        // --------------------------------================---------------------------
        // TIMBER POST INTERFACE: Heavy Structural Screw Counterbores
        // --------------------------------================================-----------
        // 4x Perimeter locations positioned clear of the internal enclosure outline
        for(x = [-(box_l/2) - 15, (box_l/2) + 15]) {
            for(y = [-(box_w/2) - 2, (box_w/2) + 2]) {
                // Shank clearance hole for 5/16" or 8mm structural timber screws
                translate([x, y, 0]) cylinder(h=40, r=4.5, center=true);
                // Deep washer/screw-head counterbore socket to preserve a flush face
                translate([x, y, (wall_t/2) + 4]) cylinder(h=10, r=9.0, center=true);
            }
        }
        
        // --------------------------------================================-----------
        // ROUGH-SAWN STUD ALIGNMENT CHANNEL (Self-centering indexer cutout)
        // --------------------------------================================-----------
        // Relieves a channel on the backside of the mount to clamp flush over a stud
        translate([0, 0, -(wall_t/2)])
            cube([box_l + 50, stud_width + 1.5, wall_t], center=true);
            
        // --------------------------------================================-----------
        // ATMOSPHERIC PRESSURE BREATHER CLEARANCE HOLE
        // --------------------------------================================-----------
        // Center cutout ensuring unrestricted airflow for the hydrophobic vent
        translate([0, 0, 0]) cylinder(h=30, r=18, center=true);
    }
}

// Render structural timber frame mounting component
color("DarkGoldenrod") heavy_timber_mount();
