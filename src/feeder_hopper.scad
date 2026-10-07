// UNIVAC IX Smart Farm Mechanical Device: Rotary Hopper Metering Valve
// Fits standard 45-degree wood hopper chutes (NDSU Beef/Poultry blueprints)

$fn = 80;
chute_width = 150;
valve_radius = 45;

module hopper_chute_adapter() {
    difference() {
        // Outer housing flanged to mount onto a wooden hopper box base
        cube([chute_width + 20, chute_width + 20, 50], center=true);
        // Internal funneling taper
        cylinder(h=55, r1=chute_width/2, r2=chute_width/3, center=true);
    }
}

module rotary_drum_valve() {
    // Continuous rotation drum with precise volume pockets
    difference() {
        cylinder(h=chute_width + 18, r=valve_radius, center=true);
        // Hexagonal drive shaft slot for the motor interface
        cylinder(h=chute_width + 30, r=8, center=true, $fn=6);
        // Metering volumetric pockets (Rotated 120 degrees apart)
        for(r=[0, 120, 240]) {
            rotate([0, 0, r]) translate([valve_radius - 12, 0, 0]) 
                cube([30, valve_radius, chute_width - 10], center=true);
        }
    }
}

// Visual rendering layout
color("SaddleBrown") translate([0, 0, 40]) hopper_chute_adapter();
color("LightSteelBlue") rotate([90, 0, 0]) rotary_drum_valve();
