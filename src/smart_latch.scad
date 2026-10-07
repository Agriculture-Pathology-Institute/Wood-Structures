// UNIVAC IX / RT Smart Farm Mechanical Device: Gravity Latch & Solenoid Bracket
// Designed for mounting on NDSU/LSU Standard Wood Post & Stud Frames

$fn = 60;
latch_length = 120;
latch_width = 30;
latch_thickness = 8;
solenoid_pocket_w = 26;
solenoid_pocket_l = 40;

module wood_mounting_plate() {
    difference() {
        // Base plate for wood screws
        cube([80, 100, 6], center=true);
        // 4x Mounting holes for heavy-duty timber screws
        for (x=[-30, 30], y=[-40, 40]) {
            translate([x, y, 0]) cylinder(h=12, r=4, center=true);
        }
    }
}

module gravity_latch_arm() {
    difference() {
        union() {
            cube([latch_length, latch_width, latch_thickness], center=false);
            // Pivot housing
            translate([10, latch_width/2, 0]) cylinder(h=latch_thickness+4, r=12, center=false);
        }
        // Pivot bolt hole (Snake-eyes tamper-resistant spanner bolt ready)
        translate([10, latch_width/2, -1]) cylinder(h=20, r=4.5, center=false);
        // Solenoid linkages slot
        translate([latch_length-25, latch_width/2, -1]) cylinder(h=20, r=3, center=false);
    }
}

module solenoid_housing_bracket() {
    // Rigid cradle for the electronic release actuator
    difference() {
        cube([solenoid_pocket_w + 12, solenoid_pocket_l + 12, 35], center=true);
        translate([0, 0, 4]) cube([solenoid_pocket_w, solenoid_pocket_l + 14, 30], center=true);
        // Plunger shaft clearance hole
        translate([0, 0, -15]) cylinder(h=20, r=6, center=true);
    }
}

// Assemble the smart mechanism
translate([0, 0, 3]) wood_mounting_plate();
translate([-40, -15, 6]) gravity_latch_arm();
translate([0, 35, 20]) rotate([90, 0, 0]) solenoid_housing_bracket();
