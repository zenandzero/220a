// chuck fakeGametrak.ck

// fake data from SinOscs

// SawOsc through resonator, parameters controlled by simulated gametrak 
// X dimension to formant freq
// Y to SawOsc freq
// Z to SawOsc gain

Gamelan g;

//SawOsc buzz => ResonZ f => NRev r => dac;
// set filter Q
//100 => f.Q;
//r.mix(0.1);

// spork control
spork ~ gametrak();
// print
spork ~ print();

// *** Constants

200 => int basis;
0.0013 => float velocityThreshold;

// *** Main variables

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

fun void print()
{
    while( true )
    {
        // values
        //<<< "axes:", gtAxis[0],gtAxis[1],gtAxis[2], gtAxis[3],gtAxis[4],gtAxis[5] >>>;
        <<< gtXYAngle >>>;
        <<< velocity >>>;
        
        100::ms => now;
    }
}

// 3-axis gametrack simulation
fun void gametrak()
{
    while( true )
    {
        // wait on HidIn as event
        basis::ms => now;
        for( 0 => int which; which < 6; which++ )
        {
            // Save last
            gtAxis[which] => gtAxisLast[which];
   
            axis[which].last() => float axisPosition;
            
            // the z axes map to [0,1], others map to [-1,1]
            if( which != 2 && which != 5 )
            { axisPosition => gtAxis[which]; }
            else
            {
                1 - ((axisPosition + 1) / 2) => gtAxis[which];
                if( gtAxis[which] < 0 ) 0 => gtAxis[which];
            }
        }
    }
}

g.strike(3, 3);

// Control loop...
while(true){
    // Angle of attack
    Math.atan(gtAxis[1] / gtAxis[0]) => gtXYAngle;
    
    // Convert from radians to degrees
    Math.fabs(gtXYAngle * (180 / Math.PI)) => gtXYAngle;
    
    Math.pow((gtAxis[0] - gtAxisLast[0]), 2) + Math.pow((gtAxis[1] - gtAxisLast[1]), 2) => distance;
    Math.sqrt(distance) => distance;
    
    distance / basis => velocity;
    
    // Strike
    if (velocity > velocityThreshold) {
        // Compute scale pitch based on angle of attach
        gtXYAngle $ int / 18 => int pitch;
        
        int octave;
        // Octave based on quadrant
        if (gtAxis[0] < 0 && gtAxis[1] > 0)      { 4 => octave; }
        else if (gtAxis[0] > 0 && gtAxis[1] > 0) { 3 => octave; }
        else if (gtAxis[0] > 0 && gtAxis[1] < 0) { 2 => octave; }
        else if (gtAxis[0] < 0 && gtAxis[1] < 0) { 1 => octave; }
        else { <<< "Never reach here" >>>; }
        
        <<< "Striking", pitch, "at octave ", octave >>>;
        g.strike(pitch, octave);
    }
    
    1::samp => now;
}