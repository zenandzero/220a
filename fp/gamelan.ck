public class Gamelan
{
    // *** Pentatonic Javanese "Salendro" scale in MIDI (D#2, F2, G2, A#2, C3)
    [39, 41, 43, 46, 48] @=> int salendro[];
    
    Gain patch => dac;
    
    // *** Model gamelan reverberation 
    JCRev rev => patch;
    
    0.1 => rev.mix;
        
    // *** Model cent deviations inherent in gamelan
    // *** For every instrument, we generate deviations to apply to each
    // *** pitch at a specific octave (we support 5 octaves here)
    // *** 
    // *** Deviations are computed by picking the number of syntonic commas
    // *** between (-1, 1) that we want to deviate by and converting to the
    // *** frequency domain
    float deviations[5][salendro.cap()];
    for (0 => int i; i < 5; i++) {
        for (0 => int j; j < salendro.cap(); j++) {
            Math.random2f(-1, 1)  * 21.51 => deviations[i][j];
        }
    }

    // *** Patch for higher frequencies based on Sqr * Sin ring modulation
    Gain high => ADSR a1 => HPF h1 => rev;
    3 => high.op;
    
    // ****** Carrier and modulating waves for high ring mod
    SinOsc r1m => high;
    SqrOsc r1c => high;
    
    // ****** Short release for high frequencies
    a1.set(0::ms, 0::ms, 1, 200::ms);
    h1.set(1500, 1);

    // *** Patch for lower frequencies based on Sin * Sin ring modulation
    Gain low => ADSR a2 => LPF l1 => rev;
    3 => low.op;
    0.1 => low.gain;

    // ****** Carrier and modulating waves for low ring mod
    SinOsc r2m => low;
    SinOsc r2c => low;
    
    // ****** Long release for low frequencies
    a2.set(0::ms, 0::ms, 0.5, 500::ms);
    l1.set(1000, 1);

    // *** Tune our gamelan's fundamental frequencies to D#2 and G3
  //  Std.mtof(38) => r2m.freq;
   // Std.mtof(55) => r1m.freq;
    
    fun void strike(float pitch, float velocity) {  
        
        pitch => r1c.freq => r2c.freq;
        
        velocity => patch.gain;
        
        a1.keyOn();
        a2.keyOn();
        
        1::ms => now;
        
        a1.keyOff();
        a2.keyOff();
    }
    
    fun void strike2(int degree, int octave, float velocity) {  
        Std.mtof(salendro[degree]) * Math.pow(2, octave) + deviations[octave][degree] => float freq;
        
        freq => r1c.freq => r2c.freq;
        
        velocity => patch.gain;
        
        a1.keyOn();
        a2.keyOn();
        
        1::ms => now;
        
        a1.keyOff();
        a2.keyOff();
    }
}