
Hid pedal;
HidMsg msg;

Event startRec;
Event stopRec;

//adc => NRev r => Echo e => dac; 

// open joystick 0, exit on fail
if( !pedal.openKeyboard( 0 ) ) me.exit();

<<< "Pedal '" + pedal.name() + "' ready", "" >>>;

// * LOOP CONTROLLER

class Loop {
    adc => LiSa looper => Gain output => dac;
    output.gain(1);
    
    10 => looper.maxVoices;
    60::second => looper.duration;
    
    <<<"buffer duration = ", looper.duration() / 48000.>>>;
    
    fun void startRecording() {
        looper.clear(); // maximum of 1 voice for now
        1 => looper.record;
    }
    
    fun void stopRecording() {
        adc =< looper;
        0 => looper.record;
    }

    fun void startPlaying(dur duration) {        
        looper.getVoice() => int voice;             
        while (true) {
            looper.rate(voice, 1);
            looper.playPos(voice, 0::ms);
            looper.play(voice, 1);
            duration => now;
        }
    }
    
    fun void stopPlaying() {
        output =< dac;
        0 => looper.play;
    }
}

fun void loopController()
{
    0 => int loopCount;
    Loop @ loops[100];
    while(true)
    {
        startRec => now;
        now => time startTime;
      
        Loop loop;
        loop.startRecording();
        
        <<< "Starting loop", loopCount >>>;
        
        loop @=> loops[loopCount];
        loopCount + 1 => loopCount;
        
        stopRec => now;
        now => time endTime;
        
        loop.stopRecording();
        spork ~ loop.startPlaying(endTime - startTime);
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
            //<<< msg, msg.which, msg.isButtonDown(), msg.isButtonUp() >>>;
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