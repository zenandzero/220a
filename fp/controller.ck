
Hid pedal;
HidMsg msg;

Event startRec;
Event stopRec;

adc => NRev r => Echo e => dac; 


// open joystick 0, exit on fail
if( !pedal.openKeyboard( 0 ) ) me.exit();

<<< "Pedal '" + pedal.name() + "' ready", "" >>>;

// * LOOP CONTROLLER

class Loop {
    WvOut w;
    SndBuf buf;
    string name;
    Event stopRec2;
    Event stopPlay;
    
    fun void setNumber(int number) {
        "loop" + number => name;
    }
    
    fun void goRecord() {
        stopRec2 => now;
    }
    
    fun void startRecording() {
        adc => w => blackhole;
        name => w.wavFilename;
        <<< "start rec" >>>;
        
        spork ~ goRecord();
    }
    
    fun void stopRecording() {
        adc =< w;
        name => w.closeFile;
        
        stopRec2.broadcast();
        
        <<< "stop rec" >>>;
    }
    
    fun void goPlay() {
      //  1 => buf.loop;
       stopPlay => now;


    }
    
    fun void startPlaying() {
        buf => dac;
        name + ".wav" => buf.read;
          
        <<< "Start playing", name >>>;
       /* // time loop
        while( true )
        {
            0 => buf.pos;
            Math.random2f(.2,.5) => buf.gain;
            Math.random2f(.5,1.5) => buf.rate;
            1000::ms => now;
            <<< "setting">>>;
        }*/

        spork ~ goPlay();        
    }
    
    fun void stopPlaying() {
        buf =< dac;        
        stopPlay.broadcast();
        <<< "Stop playing", name >>>;
    }
}

fun void loopController()
{
    0 => int loopCount;
    Loop @ group[1000];
    while(true)
    {
        startRec => now;
      
        Loop newLoop;
        loopCount => newLoop.setNumber;
        newLoop.startRecording();
        
        loopCount + 1 => loopCount;
        
        stopRec => now;
        
        newLoop.stopRecording();
        newLoop.startPlaying();

    }
}


// * PEDAL MONITOR

fun void pedalMonitor()
{
    while( true )
    {
        // wait on HidIn as event
        pedal => now;

        // messages received
        while( pedal.recv( msg ) )
        {
            <<< msg, msg.which, msg.isButtonDown(), msg.isButtonUp() >>>;
            if(msg.isButtonDown())
            {
                if (msg.which == 75) { // left pedal, start recording
                    <<< "start" >>>;
                    startRec.broadcast();
                } else if (msg.which == 78) { // right pedal, start recording
                    <<< "stop" >>>;
                    stopRec.broadcast();
                }   
            }
            
        }
    }
}

// * START STUFF

spork ~ pedalMonitor();
spork ~ loopController();

while (true) {
	1::samp => now;
}
