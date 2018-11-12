// chuck gamelan.ck controller.ck

Gamelan g;

spork ~ gametrak();
spork ~ print();

// *** Constants

0.05 => float accelerationPeak;
0.01 => float threshold;

// *** Main variables

float acceleration;
float velocityLast;

float gtXYAngle;
float velocity;
float distance;
float gtAxisLast[6];
float gtAxis[6];
SinOsc axis[6];

for( 0 => int i; i < 6; i++ ) {
    axis[i] => blackhole;
    axis[i].freq( 0.2 / (i+1)$float);
}

fun void print() {
    while(true) {
        //<<< "axes:", gtAxis[0],gtAxis[1],gtAxis[2], gtAxis[3],gtAxis[4],gtAxis[5] >>>;
       // <<< gtXYAngle >>>;
            //<<< velocity >>>;
        100::ms => now;
    }
}

// 3-axis gametrack simulation
fun void gametrak() {
    while(true) {
        // wait on HidIn as event
        200::ms => now;
        for(0 => int which; which < 6; which++) {
            // Save last
            gtAxis[which] => gtAxisLast[which];
   
            axis[which].last() => float axisPosition;
            
            // the z axes map to [0,1], others map to [-1,1]
            if( which != 2 && which != 5 ) {
                axisPosition => gtAxis[which];
            } else {
                1 - ((axisPosition + 1) / 2) => gtAxis[which];
                if( gtAxis[which] < 0 ) 0 => gtAxis[which];
            }
        }
    }
}

// Get angle of attack
fun float angle(float x, float y) {
    return Math.atan2(y, x) * (180 / Math.PI);
}

// Map coordinates to angle and pitch
fun int pitch(float x, float y) {
    angle(x, y) => float gtXYAngle;
    
    int pitch;
    if (gtXYAngle >= 90 && gtXYAngle < 162) { 0 => pitch; }
    else if (gtXYAngle >= 18 && gtXYAngle < 90) { 1 => pitch; }
    else if (gtXYAngle >= -54 && gtXYAngle < 18) { 2 => pitch; }
    else if (gtXYAngle >= -126 && gtXYAngle < -54) { 3 => pitch; }
    else if (gtXYAngle >= 162 || gtXYAngle < -126) { 4 => pitch; }
    else { <<< "Never reach here" >>>; }
    
    return pitch;
}

fun int octave(float x, float y) {
    angle(x, y) => float gtXYAngle;
    
    int octave;
    if (gtXYAngle >= 45 && gtXYAngle < 135) { 0 => octave; }
    else if (gtXYAngle >= -45 && gtXYAngle < 45) { 1 => octave; }
    else if (gtXYAngle >= -135 && gtXYAngle < -45) { 2 => octave; }
    else if (gtXYAngle >= 135 || gtXYAngle < -135) { 3 => octave; }
    else { <<< "Never reach here" >>>; }
    
    return octave;
}

fun float calculateAcceleration() {
    // Remember last value
    velocity => velocityLast;
    
    // Compute distance travelled
    Math.pow((gtAxis[0] - gtAxisLast[0]), 2) + Math.pow((gtAxis[1] - gtAxisLast[1]), 2) => distance;
    
    // Squint and call that velocity
    Math.sqrt(distance) => velocity;
    velocityLast - velocity => acceleration;
}

// Main control loop
while(true){
    calculateAcceleration();

    acceleration / accelerationPeak => float gain;
    <<< acceleration, gain >>>;

    // Strike
    if (gain > threshold) {
        <<< "Striking" >>>;
        pitch(gtAxis[0], gtAxis[1]) => int pitch;
        octave(gtAxis[0], gtAxis[1]) => int octave;
        g.strike(pitch, octave, gain);
    }
    
    1::samp => now;
}