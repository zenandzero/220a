//-----------------------------------------------------------------------------
// name: LiSa
// desc: Live sampling utilities for ChucK
//
// author: Dan Trueman, 2007
//
// to run (in command line chuck):
//     %> chuck LiSa_readme.ck
//-----------------------------------------------------------------------------

/*

These three example files demonstrate a couple ways to approach granular sampling
with ChucK and LiSa. All are modeled after the munger~ from PeRColate. One of the
cool things about doing this in ChucK is that there is a lot more ready flexibility
in designing grain playback patterns; rolling one's own idiosyncratic munger is 
a lot easier. 

Example 3 (below) uses the same structure as Example 2, but replicates the groovy
tune munging from the original munger~ helppatch (with pitch transposition filtering
and all!).

*/

//-----------------------------------------------------------------------------
//oscillator as source
//SinOsc s=>dac;
//s.freq(440.);
//s.gain(0.2);

//play the munger song!
//Envelope fsmooth => blackhole;
//spork ~ playtune(250::ms);
//spork ~ smoothtune(20::ms);

public class Granular {

// Instance variables

Gain in;
Gain out;
50::ms => dur duration;

//transposition table
[0, 4, 7, -2, 12, 15] @=> int pitchtable[];

//use three buffers to avoid clicks
LiSa l[3];
1::second 		=> dur bufferlen; //allocated buffer size -- remains static
0.1::second 	=> dur reclooplen;//portion of the buffer size to use -- can vary
0 => int recbuf;
2 => int playbuf;

//LiSa params, set
for(0=>int i; i<3; i++) {
    
    l[i].duration(bufferlen);
    l[i].loopEndRec(reclooplen);
    l[i].maxVoices(30);
    l[i].clear();
    l[i].gain(0.2);
    //if you want to retain earlier passes through the recording buff when loop recording:
    //l[i].feedback(0.5); 
    l[i].recRamp(20::ms); //ramp at extremes of record buffer while recording
    l[i].record(0);
    
    in => l[i] => out;
}

spork ~ startGranular();

 fun void startGranular() {
    
    //start recording in buffer 0
    l[recbuf].record(1);
    
    //create grains, rotate record and play bufs as needed
    //shouldn't click as long as the grainlen < bufferlen
    while(true) {
        
        //will update record and playbufs to use every reclooplen
        now + reclooplen => time later;
        
        //toss some grains
        while (now<later) {
            
            Std.rand2f(0, 6) $ int => int newpitch; //choose a transposition from the table
            Std.mtof(pitchtable[newpitch] + 60)/Std.mtof(60) => float newrate;
            //Std.rand2f(50, 100) * 1::ms => dur newdur; //create a random duration for the grain
            
         //  <<< "Spork grain with duration", duration >>>;
            
            //spork off the grain!
            spork ~ getgrain(playbuf, duration, 20::ms, 20::ms, newrate);
            
            //wait a bit.... then do it again, until we reach reclooplen
            5::ms => now;
        
    }
    
    //rotate the record and playbufs
    l[recbuf++].record(0);
    if(recbuf == 3) 0 => recbuf;
    l[recbuf].record(1);
    
    playbuf++;
    if(playbuf == 3) 0 => playbuf;
    
}
}


//for sporking grains; can do lots of different stuff here -- just one example here
fun void getgrain(int which, dur grainlen, dur rampup, dur rampdown, float rate)
{
    l[which].getVoice() => int newvoice;
    
    if(newvoice > -1) {
        l[which].rate(newvoice, rate);
        l[which].playPos(newvoice, Std.rand2f(0., 1.) * reclooplen);
        l[which].rampUp(newvoice, rampup);
        (grainlen - (rampup + rampdown)) => now;
        l[which].rampDown(newvoice, rampdown);
        rampdown => now;
    }
    
}

}