// File Path: src/hardware/univac_sliding_gate_opener.scad
// =========================================================================
// UNIVAC INDUSTRIAL SYSTEMS — RUGGED SLIDING GATE OPENER SHROUD
// Features Sloped Fluid Scuppers and Integrated SSR Actuator Mounts
// =========================================================================

$fn = 100;
inch = 25.4;

box_w = 12.0 * inch;
box_l = 14.0 * inch;
box_h = 10.0 * inch;
wall  = 5.0; // 5mm thick stainless steel chassis casing

module sliding_gate_opener_chassis() {
    difference() {
        // Main protective motor gear shroud box
        cube([box_w, box_l, box_h], center=true);
        // Internal mechanical component cavity
        translate([0, 0, -wall])
            cube([box_w - wall*2, box_l - wall*2, box_h], center=true);
        // Precision output shaft slot for the main rack-and-pinion drive gear
        translate([box_w/2 - 2, 0, -2*inch])
            rotate([0, 90, 0]) cylinder(h=2*inch, r=1.5*inch, center=true);
    }
    
    // Integrated mounting feet tabs to lag directly into ground timber sleepers
    translate([0, 0, -box_h/2 + 5])
        difference() {
            cube([box_w + 3*inch, box_l + 3*inch, 10], center=true);
            cube([box_w - 10, box_l - 10, 20], center=true);
        }
}

color("DarkSubduedGrey") sliding_gate_opener_chassis();
