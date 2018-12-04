
Hid pedal;
HidMsg msg;

Event startRec;
Event stopRec;


// open joystick 0, exit on fail
if( !pedal.openKeyboard( 0 ) ) me.exit();

<<< "Pedal '" + pedal.name() + "' ready", "" >>>;

// * LOOP CONTROLLER

class Loop {
    WvOut w;
    SndBuf buf;
    string name;
    Event stopRec;
    Event stopPlay;
    int stopped;
    
    fun void setNumber(int number) {
        "loop" + number => name;
    }
    
    fun void goRecord() {
        stopRec => now;
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
        
        stopRec.broadcast();
        
        <<< "stop rec" >>>;
    }
    
    fun void goPlay() {
        while (!stopped) {
            buf.length() / buf.rate() => now;
        }
    }
    
    fun void startPlaying() {
        buf => dac;
        name + ".wav" => buf.read;
        1 => buf.loop;
        0 => stopped;
        
        spork ~ goPlay();
        <<< "Start", name >>>;
    }
    
    fun void stopPlaying() {
        buf =< dac;
        1 => stopped;
        
        <<< "Stop", name >>>;
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

1::day => now;