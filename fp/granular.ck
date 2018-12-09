// Overall structure and inspiration for this file borrowed from:
// http://wiki.cs.princeton.edu/index.php/LiSa_munger3.ck

public class Granular {
    // Instance variables
    Gain in;
    Gain out;
    20::ms => dur duration;

    LiSa l[3];
    1::second => dur bufferlen; //allocated buffer size -- remains static
    0.1::second => dur reclooplen;//portion of the buffer size to use -- can vary
    0 => int recbuf;
    2 => int playbuf;
    
    //LiSa params, set
    for(0 => int i; i<3; i++) {
        l[i].duration(bufferlen);
        l[i].loopEndRec(reclooplen);
        l[i].maxVoices(30);
        l[i].clear();
        l[i].gain(1);
        l[i].feedback(0.5); 
        l[i].record(0);
        in => l[i] => out;
    }
    
    spork ~ startGranular();
    
    fun void startGranular() {
        l[recbuf].record(1);
        
        while(true) {
            now + reclooplen => time later;

            while (now<later) {
                spork ~ getgrain(playbuf, duration);
                2::ms => now;
            }
            
            // Rotate buffers
            l[recbuf++].record(0);
            if(recbuf == 3) 0 => recbuf;
            l[recbuf].record(1);
            
            playbuf++;
            if(playbuf == 3) 0 => playbuf;
        }
    }
    
    fun void getgrain(int which, dur grainlen){
        l[which].getVoice() => int newvoice;
        if(newvoice > -1) {
            l[which].rate(newvoice, 1.0);
            l[which].playPos(newvoice, 0::second);
            l[which].rampUp(newvoice, 0::ms);
            grainlen  => now;
            l[which].rampDown(newvoice, 0::ms);
        }
    }
}