class Logistic
{
    float _x, _r;
    false => int isSet;
    fun void set( float x, float r )
    {
        x => _x;
        r => _r;
        true => isSet;
    }
    fun float tick( )
    {
        if (!isSet) 
        {
            <<<"Logistic not set, quitting","\ntry adding something like... 
            <your_obj>.set(0.7, 3.1); 
            // for initial x value and r coefficient">>>;
            me.exit();
        }
        (_r * _x) * (1.0 - _x) => _x;
        return _x;
    }
}
Logistic map;
map.set(0.2, 4);

adc.chan(0) => Gain inGain => FFT fft =^ Centroid cent => blackhole;
fft =^ RMS rms => blackhole;

Instrument i;

// set parameters
1024 => fft.size;
// set hann window
Windowing.hamming(fft.size()) => fft.window;

// compute srate
second / samp => float srate;
Step unity => Envelope cEnv => blackhole;
unity => Envelope rEnv => blackhole;
cEnv.duration(fft.size()::samp);
rEnv.duration(fft.size()::samp);
float c, r;

float last;

fun void smoothUpdates() // to SinOsc from envelopes
{
  while( true )
  {
    Math.pow(map.tick(), 2) => float tick;
    
    1 => int freqMultiplier;
    if (Math.random2(0, 1) > 0.7) {
        2 => freqMultiplier;
    } else if (Math.random2(0, 1) > 0.8) {
        4 => freqMultiplier;
    } else if (Math.random2(0, 1) > 0.9) {
        8 => freqMultiplier;
    } else if (Math.random2(0, 1) > 0.95) {
        3 => freqMultiplier;
    }
    
    i.play(tick::second, last * freqMultiplier, rEnv.last());

    tick::second => now;
  }
}

cEnv.target(Std.mtof(60));
rEnv.target(0.06);

spork ~smoothUpdates();
// control loop
while( true )
{
    rms.upchuck() @=> UAnaBlob blob;
    blob.fval(0) => r;
    
    // If there's this much coming from adc...
    if (r > 0.00005) {
                
        // ... then sample frequency but don't play
        rEnv.target(0);
        
        1.5::second + now => time end;
        while (now < end) {
            cent.upchuck();
            cent.fval(0) * srate / 2 => c;
            fft.size()::samp => now;
        }
        
        c => last;
    } else {
        rEnv.target(0.06 - r);
    }

    fft.size()::samp => now;
}
