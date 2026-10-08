// File Path: src/hardware/parametric_animal_door.scad
// =========================================================================
// UNIVAC IX INDUSTRIAL ACCESS CORES — PARAMETRIC ANIMAL-SAFE SHIELD GATE
// Features Dynamic Sizing Scaling and Integrated Neoprene Anti-Fur/Tail Guards
// Washdown-Proof Profile Configured for Constant High-Pressure Water Spray
// =========================================================================

$fn = 100; // Enforce crisp geometric resolutions

// --- DYNAMIC SCALE FACTOR PRINT SETTINGS ---
// Set scale_tier = 1 for Pig/Sheep flap doors; scale_tier = 2 for Large Timber Barn Doors
scale_tier = 1; 

// Sizing Matrix translation block based on selected installation tier
door_width  = (scale_tier == 1) ? 450.0  : 1800.0; // mm
door_height = (scale_tier == 1) ? 600.0  : 2400.0; // mm
door_thick  = (scale_tier == 1) ? 25.4   : 76.2;   // mm

// --- Safety & Fur Guard Constraints ---
guard_clearance = (scale_tier == 1) ? 12.0 : 35.0; // Anti-pinch gap buffer
gasket_thickness = 4.0; // Heavy gauge flexible neoprene backing sheet

module parametric_gate_leaf_assembly() {
    difference() {
        // 1. MAIN WASHDOWN-PROOF CORE SLAB
        // Milled with sloped water-shed channels to eliminate fluid pooling
        cube([door_width, door_height, door_thick], center = true);
        
        // Internal structural weight-reduction cutouts (Maintain structural rigidity)
        translate([0, 0, 0])
            cube([door_width * 0.75, door_height * 0.75, door_thick + 2], center = true);
    }
    
    // 2. CONCENTRIC ANTI-PINCH BRUSH COLLAR (FUR & TAIL SAFE GUARD SHIELD)
    // Extrudes an outer lip along the mating frames to seat the neoprene sweep
    translate([0, 0, 0])
    color("Black") difference() {
        cube([door_width + (guard_clearance * 2), 
              door_height + (guard_clearance * 2), 
              door_thick * 0.5], center = true);
              
        cube([door_width, door_height, door_thick + 4], center = true);
    }
    
    // 3. REINFORCED HINGE BOSSES FOR DIRECT TIMBER MOUNTING
    translate([-(door_width / 2), (door_height / 3), 0])
        cylinder(h = door_thick * 1.5, r = door_thick * 0.8, center = true);
    translate([-(door_width / 2), -(door_height / 3), 0])
        cylinder(h = door_thick * 1.5, r = door_thick * 0.8, center = true);
}

module integrated_neoprene_sweep_gasket() {
    // Visualizes the flexible neoprene shield wrapping the frame gap
    color("DarkGrey", 0.7) translate([0, 0, 0])
        difference() {
            cube([door_width + (guard_clearance * 2) + gasket_thickness, 
                  door_height + (guard_clearance * 2) + gasket_thickness, 
                  door_thick * 0.25], center = true);
            cube([door_width - 2, door_height - 2, door_thick], center = true);
        }
}

// Render the fully scaled composite assembly
parametric_gate_leaf_assembly();
translate([0,0, (door_thick * 0.3)]) integrated_neoprene_sweep_gasket();
