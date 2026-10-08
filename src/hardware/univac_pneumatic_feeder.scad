// File Path: src/hardware/univac_pneumatic_feeder.scad
// =========================================================================
// UNIVAC INDUSTRIAL SYSTEMS — PARAMETRIC HIGH-VOLUME PNEUMATIC FEEDER
// Washdown-Proof Geometric Profile with Sloped Shed Basins
// =========================================================================

$fn = 100;
inch = 25.4;

hopper_upper_dia = 20.0 * inch; // Wide ingestion funnel (~508mm)
hopper_lower_dia = 4.0 * inch;  // Output throat mapping to pneumatic pipes
hopper_height    = 18.0 * inch; 
wall_thickness   = 6.0;         // Reinforced impact-resistant polymer

module pneumatic_feeder_assembly() {
    // 1. MAIN SLOPED SHED HOPPER FUNNEL
    difference() {
        cylinder(h=hopper_height, r1=hopper_upper_dia/2, r2=hopper_lower_dia/2, center=false);
        // Hollow internal path
        translate([0, 0, -1])
            cylinder(h=hopper_height + 2, r1=(hopper_upper_dia - wall_thickness*2)/2, r2=(hopper_lower_dia - wall_thickness*2)/2, center=false);
    }
    
    // 2. INDUSTRIAL MOUNTING FLANGE
    // Reinforced collar to anchor directly to barn timber cross-beams
    translate([0, 0, hopper_height - 1*inch])
        difference() {
            cylinder(h=1*inch, r=(hopper_upper_dia/2) + 2*inch, center=false);
            translate([0, 0, -1])
                cylinder(h=1*inch + 2, r=(hopper_upper_dia/2) + 0.1*inch, center=false);
            // Programmatic mounting bolt holes matrix
            for (a = [0 : 45 : 360]) {
                rotate([0, 0, a]) translate([(hopper_upper_dia/2) + 1*inch, 0, -1])
                    cylinder(h=1*inch + 2, r=0.5*inch/2);
            }
        }
}

color("CadetBlue") pneumatic_feeder_assembly();
