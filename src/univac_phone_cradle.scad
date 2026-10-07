// ===================================================================================
// UNIVAC IX Smart Farm Mechanical Layer: Vintage Telephony Enclosure Cradle
// Engineered for heavy vintage field sets mounted to multi-ply LVL or rough studs
// ===================================================================================

$fn = 80;

// Vintage UNIVAC Telephone Housing dimension variables
phone_w = 140;         // Standard width of heavy cast-iron phone base mount footprint
phone_l = 220;         // Vertical height footprint of phone chassis backplate
wall_t = 10;           // Thick 10mm structural wall profile to sustain hand-crank torque
cradle_depth = 35;     // Protective retention flange depth for phone box
stud_width = 50.8;     // 2-inch rough-sawn dimensional timber indexing reference

module univac_phone_cradle() {
    difference() {
        union() {
            // 1. Primary Reinforced Cradle Structural Block
            cube([phone_w + (wall_t * 2), phone_l + (wall_t * 2), cradle_depth], center=true);
            
            // 2. Dual Side Flanged Heavy-Duty Mounting Wings
            translate([0, 0, -(cradle_depth/2) + 4])
                cube([phone_w + (wall_t * 6), phone_l - 40, 8], center=true);
        }
        
        // --------------------------------===========================================
        // A. RETENTION COMPARTMENT: Main Cavity for the Telephone Housing
        // --------------------------------===========================================
        translate([0, 0, wall_t/2 + 2])
            cube([phone_w, phone_l, cradle_depth], center=true);
            
        // --------------------------------===========================================
        // B. WIRING PASS-THROUGH: 12-Pin Twist Lock Interconnect Opening
        // --------------------------------===========================================
        // Center cutout allows the 12-pin twist-lock cabling fabric to pass underneath
        translate([0, -(phone_l/2) + 30, -cradle_depth]) 
            cylinder(h=50, r=22, center=true);
            
        // --------------------------------===========================================
        // C. STRUCTURAL ANCHORS: 4x Heavy-Duty Timber Ledger Screw Counterbores
        // --------------------------------===========================================
        // Located on the wide exterior mounting wings for easy driver drill clearance
        for(x = [-(phone_w/2) - 24, (phone_w/2) + 24]) {
            for(y = [-(phone_l/2) + 40, (phone_l/2) - 40]) {
                // Shank clearance channel for 5/16" or 8mm structural ledger screws
                translate([x, y, -cradle_depth]) cylinder(h=50, r=4.5, center=true);
                // Wide counterbore pocket to sink the bolt head flush with the wing surface
                translate([x, y, -(cradle_depth/2) + 4]) cylinder(h=10, r=9.5, center=true);
            }
        }
        
        // --------------------------------===========================================
        // D. TIMBER ALIGNMENT: Backside Rough-Sawn Stud Self-Centering Channel
        // --------------------------------===========================================
        // 120-Degree V-Notch carved into the back face allowing a lock on 2" studs/poles
        translate([0, 0, -(cradle_depth/2) - 1])
            rotate([0, 45, 0])
                cube([stud_width, phone_l + 30, stud_width], center=true);
    }
}

// Render structural telephone housing cradle unit
color("DarkOliveGreen") univac_phone_cradle();
