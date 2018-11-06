// kijjaz's Table Rimshot 01 - version 0.1 testing with Ramdomwalk patch 

440.0 => float freq; 
.5 => float randomRange; 
.95 => float decay; 
(second / samp / freq) $ int => int samples; 

float table[samples]; 

SinOsc s => dac;
2000 => s.freq;
0.01 => s.gain;


s=> Dyno compressor => dac; 

//Step s => Dyno compressor => dac; 
//s.gain(.5); 
compressor.compress(); 
compressor.thresh(.1); 

20::second => now;