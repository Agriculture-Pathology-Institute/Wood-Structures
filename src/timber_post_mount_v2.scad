// ===================================================================================
// UNIVAC IX Smart Farm Mechanical Layer: Heavy Timber Mounting Adapter Assembly
// Optimized for built-up multi-ply LVL posts, header columns, and dimensional studs
// ===================================================================================

$fn = 80;

// Enclosure Base alignment metrics (Matches your weatherproof chassis profile)
box_l = 150;
box_w = 110;
wall_t = 6;            // Increased wall thickness to survive extreme structural tension
standoff_h = 8;        // Thermal air-gap separation for environmental breathing
stud_width = 50.8;     // 2-inch rough-sawn dimensional lumber width indexer reference

module heavy_timber_mount() {
    difference() {
        union() {
            // 1. Primary Heavy-Duty Reinforced Base Adapter Plate
            cube([box_l + 44, box_w + 20, wall_t], center=true);
            
            // 2. 4x Enclosure Mounting Standoffs (Creates moisture ventilation gap)
            for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
                for(y = [-35, 35]) {
                    translate([x, y, (wall_t/2) + (standoff_h/2)])
                        cylinder(h=standoff_h, r=10, center=true);
                }
            }
            
            // 3. Thick Structural Support Buttress Ribs to combat ledger screw torque
            for (x = [-(box_l/2) - 16, (box_l/2) + 16]) {
                translate([x, 0, (wall_t/2) + 2])
                    cube([12, box_w + 14, 4], center=true);
            }
        }
        
        // --------------------------------===========================================
        // A. CHASSIS INTERFACE: 4x Machine Fastener Thru-Holes (M6 Clearance Size)
        // --------------------------------================================-----------
        for(x = [-(box_l/2) - 12, (box_l/2) + 12]) {
            for(y = [-35, 35]) {
                // Thru-hole for locking down the chassis base to the bracket assembly
                translate([x, y, 0]) cylinder(h=50, r=3.2, center=true);
                // Hex nut captive pocket recessed into underside of the bracket plate
                translate([x, y, -(wall_t/2) - 1]) cylinder(h=3.5, r=6.2, center=true, $fn=6);
            }
        }
        
        // --------------------------------===========================================
        // B. HEAVY TIMBER INTERFACE: 4x Perimeter Ledger Screw Anchor Points
        // --------------------------------===========================================
        // Positioned outside the footprint to allow fast field drilling access
        for(x = [-(box_l/2) - 16, (box_l/2) + 16]) {
            for(y = [-(box_w/2) - 4, (box_w/2) + 4]) {
                // Shank clearance channel for 5/16" or 8mm structural ledger screws
                translate([x, y, 0]) cylinder(h=50, r=4.5, center=true);
                // Deep washer/screw-head counterbore socket to preserve a flush outer profile
                translate([x, y, (wall_t/2) + 4]) cylinder(h=10, r=9.5, center=true);
            }
        }
        
        // --------------------------------===========================================
        // C. ROUGH-SAWN STUD ALIGNMENT CHANNEL (Self-Centering Notch)
        // --------------------------------================================-----------
        // Relieves a structural recess channel on the back to clamp flush over studs
        translate([0, 0, -(wall_t/2)])
            cube([box_l + 60, stud_width + 1.5, wall_t], center=true);
            
        // --------------------------------===========================================
        // D. HYDROPHOBIC VENT BREATHER AIR HOLE
        // --------------------------------===========================================
        // Center core cutout ensuring zero airflow blockage for the Gore breather plug
        translate() cylinder(h=50, r=18, center=true);
    }
}

// Instantiate the structural timber adapter layout
color("SlateGray") heavy_timber_mount();
