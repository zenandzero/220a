public class Instrument {
    FMFS fm;
    float cAmp;
    float cADSR[];
    float mRatio;
    float mIndex;
    float mADSR[];
    float gain;
    
    int num;
        
    fm.out => Echo e => NRev r => dac;
    
    [.001,.4,1.0,.5] @=> cADSR;   
    [.001,.4,1.0,.5] @=> mADSR;
    
    1 => mRatio;
    5 => mIndex;

    fun void play(dur length, float pitch, float gain) {
        fm.playFM(length, pitch, cADSR, mRatio, mIndex, mADSR, gain);
    }
}

class FMFS
{ // two typical uses of the ADSR envelope unit generator...
    Step unity => ADSR envM => blackhole; //...as a separate signal
    SinOsc mod => blackhole;
    SinOsc car => ADSR envC => Gain out;  //...as an inline modifier of a signal
    car.gain(2);
    float freq, index, ratio; // the parameters for our FM patch
    
    fun void fm() // this patch is where the work is
    {
        while (true)
        {
            envM.last() * index => float currentIndex; // time-varying index
            mod.gain( freq * currentIndex );    // modulator gain (index depends on frequency)
            mod.freq( freq * ratio );           // modulator frequency (a ratio of frequency) 
            car.freq( freq + mod.last() );      // frequency + modulator signal = FM 
            1::samp => now;
        }
    }
    spork ~fm(); // run the FM patch
    
    // function to play a note on our FM patch
    fun void playFM( dur length, float pitch, float cADSR[], float mRatio, float mGain, float mADSR[], float gain) 
    {
        gain => car.gain;
        
        // set patch values
        pitch => freq;
        mRatio => ratio;
        mGain => index;
        // run the envelopes
        spork ~ playEnv( envC, length, cADSR );
        spork ~ playEnv( envM, length, mADSR );
        length => now; // wait until the note is done
    }
    
    fun void playEnv( ADSR env, dur length, float adsrValues[] )
    {
        // set values for ADSR envelope depending on length
        length * adsrValues[0] => dur A;
        length * adsrValues[1] => dur D;
        adsrValues[2] => float S;
        length * adsrValues[3] => dur R;
        
        // set up ADSR envelope for this note
        env.set( A, D, S, R );
        // start envelope (attack is first segment)
        env.keyOn();
        // wait through A+D+S, before R
        length-env.releaseTime() => now;
        // trigger release segment
        env.keyOff();
        // wait for release to finish
        env.releaseTime() => now;
    }
    
}
