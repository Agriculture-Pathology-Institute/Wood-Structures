// File Path: src/hardware/univac_timber_latch.scad
// =========================================================================
// UNIVAC INDUSTRIAL SYSTEMS — HEAVY SOLID-STATE TIMBER INTERLOCK LATCH
// Designed for Direct Mounting onto Heavy Timber Barn Beams
// =========================================================================

$fn = 100;
inch = 25.4;

latch_body_w = 4.0 * inch;
latch_body_l = 8.0 * inch;
latch_body_h = 3.0 * inch;

module timber_latch_assembly() {
    difference() {
        // Solid heavy-gauge steel latch deadbolt receiver block
        cube([latch_body_w, latch_body_l, latch_body_h], center=true);
        
        // Central sliding channel for the heavy locking pin bolt
        cube([2.0*inch, latch_body_l + 10, 1.5*inch], center=true);
        
        // Heavy-duty timber lag bolt counter-sunk mounting holes
        translate([-latch_body_w/3, latch_body_l/3, 0]) cylinder(h=latch_body_h+2, r=0.375*inch, center=true);
        translate([latch_body_w/3, latch_body_l/3, 0])  cylinder(h=latch_body_h+2, r=0.375*inch, center=true);
        translate([-latch_body_w/3, -latch_body_l/3, 0]) cylinder(h=latch_body_h+2, r=0.375*inch, center=true);
        translate([latch_body_w/3, -latch_body_l/3, 0])  cylinder(h=latch_body_h+2, r=0.375*inch, center=true);
    }
}

color("Charcoal") timber_latch_assembly();
