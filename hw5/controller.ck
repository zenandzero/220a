// chuck gamelan.ck controller.ck

Gamelan g;

spork ~ gametrak();
spork ~ print();

// *** Constants

0.4 => float velocityPeak;
0.2 => float threshold;
200::ms => dur minDiff;

// *** Main variables

float gtXYAngle;
float velocity;
float distance;
// sentinel variable to tell us whether or not we've processed latest Hid events
int processed;
time lastStrike;

// *** Gametrak handling

class GameTrak {
    time lastTime;
    time currTime;
    
    float lastAxis[6];
    float axis[6];
}

GameTrak gt;

// HID objects
Hid trak;
HidMsg msg;

0 => int device;
if( !trak.openJoystick( device ) ) me.exit();

<<< "joystick '" + trak.name() + "' ready", "" >>>;

fun void gametrak() {
    while (true) {
        trak => now;
        0 => processed;
        // messages received
        while( trak.recv( msg ) ) {
            // joystick axis motion
            if( msg.isAxisMotion() ) {            
                // check which
                if( msg.which >= 0 && msg.which < 6 ) {
                    // check if fresh
                    if( now > gt.currTime ) {
                        // time stamp
                        gt.currTime => gt.lastTime;
                        // set
                        now => gt.currTime;
                    }
                    
                    // save last
                    gt.axis[msg.which] => gt.lastAxis[msg.which];
                    // the z axes map to [0,1], others map to [-1,1]
                    if( msg.which != 2 && msg.which != 5 ) {
                        msg.axisPosition => gt.axis[msg.which];
                    } else {
                        1 - ((msg.axisPosition + 1) / 2) => gt.axis[msg.which];
                        if( gt.axis[msg.which] < 0 ) 0 => gt.axis[msg.which];
                    }
                }
            }
        }
    }
}


fun void print() {
    while(true) {
        //<<< velocity >>>;
        100::ms => now;
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

fun float calculateVelocity() {
    // Compute distance travelled
    Math.pow((gt.axis[0] - gt.lastAxis[0]), 2) + Math.pow((gt.axis[1] - gt.lastAxis[1]), 2) => distance;
    
    // Squint and call that velocity
    Math.sqrt(distance) => velocity;
}

// Main control loop
while(true){
    calculateVelocity();

    velocity / velocityPeak => float gain;

     if (now - lastStrike >= minDiff && !processed && velocity > threshold) {
        now => lastStrike;
        1 => processed;
        pitch(gt.axis[0], gt.axis[1]) => int pitch;
        octave(gt.axis[3], gt.axis[4]) => int octave;
         
        <<< pitch, octave >>>;
         
        g.strike(pitch, octave, gain);
    }
    
    1::samp => now;
}