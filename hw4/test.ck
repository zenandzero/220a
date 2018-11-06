// patch
adc => Gain g => OnePole p => blackhole;
// square the input
adc => g;
// multiply
3 => g.op;

// set pole position
0.99 => p.pole;

// loop on
while( true )
{
    if( p.last() > 0.01 )
    {
        <<< "BANG!!" >>>;
        80::ms => now;
    }
    20::ms => now;
}