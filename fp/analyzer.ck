Gamelan g;

adc => Gain inGain => FFT fft =^ Centroid cent => blackhole;
fft =^ RMS rms => blackhole;

// set parameters
2048 => fft.size;
// set hann window
Windowing.hann(fft.size()) => fft.window;

// compute srate
second / samp => float srate;

float frequency, amplitude;

while( true )
{
    rms.upchuck() @=> UAnaBlob blob;
    blob.fval(0) => amplitude;
    
    
    // If there's this much coming from adc...
    if (amplitude > 0.0001) {
                
        // ... then sample frequency but don't play
       // rEnv.target(0);
        
        40::ms + now => time end;
        while (now < end) {
            cent.upchuck();
            cent.fval(0) * srate / 2 => frequency;
            fft.size()::samp => now;
        }
        
        <<< "frequency", frequency >>>;
            <<< "amplitude", amplitude >>>;

        g.strike(frequency, 1);

     }

    fft.size()::samp => now;
}
