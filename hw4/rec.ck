
dac => WvOut w0 => blackhole;
adc => WvOut w1 => blackhole;

// this is the output file name
"synchronism" + 0 + ".wav" => w0.wavFilename;
null @=> w0;

"synchronism" + 1 + ".wav" => w1.wavFilename;
null @=> w1;

// infinite time loop...
// ctrl-c will stop it, or modify to desired duration
while( true ) 1::second => now;
