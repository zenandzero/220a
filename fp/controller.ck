// chuck expression_pedal_event.ck pedal_event.ck pedal.ck granular.ck controller.ck rec.ck 
//
// Constants

0.05 => float DEFAULT_GAIN;

0.0 => float START_SMALL_CRESCENDO;
DEFAULT_GAIN * 4 => float END_SMALL_CRESCENDO;
1::minute => dur DUR_SMALL_CRESCENDO;

DEFAULT_GAIN => float START_BIG_CRESCENDO;
0.4 => float END_BIG_CRESCENDO;
30::second => dur DUR_BIG_CRESCENDO;

END_BIG_CRESCENDO => float START_SMALL_DECRESCENDO_FIRST;
END_SMALL_CRESCENDO => float START_SMALL_DECRESCENDO_SECOND;
0.0 => float END_SMALL_DECRESCENDO;
30::second => dur DUR_SMALL_DECRESCENDO;

500::ms => dur MAX_DELAY;
250::ms => dur MIN_DELAY;
0.95 => float DEFAULT_DELAY_GAIN;

0.02 => float DEFAULT_REVERB;

150::ms => dur MAX_GRANULAR_DURATION;
1::ms => dur MIN_GRANULAR_DURATION;
0.1 => float DEFAULT_GRANULAR_GAIN;

9 => int LOOP_COUNT;

// Main monitor patch

adc => NRev r => Gain pre => Gain output => dac;

DelayA delay;
Granular granular;

// Other globals

0 => int didBigCrescendo;

// Set constants

DEFAULT_REVERB => r.mix;
MAX_GRANULAR_DURATION => granular.duration;
DEFAULT_GRANULAR_GAIN => granular.out.gain;
DEFAULT_DELAY_GAIN => delay.gain;
MAX_DELAY => delay.max;
MIN_DELAY => delay.delay;

DEFAULT_GAIN * 2 => output.gain;

class Env {
    Step s => Envelope e => blackhole;
    fun void duration(dur duration) { e.duration(duration); }
    fun void value(float val) { e.value(val); }
    fun void target(float val) { e.target(val); }
    
    fun void countdown(time start) {
        0 => int secondCount;
        while (now < start + e.duration()) {
            <<< secondCount++ >>>;
            1::second => now;
        }
    }
    
    fun void go(UGen output) {
        now => time start;
        spork ~ countdown(start);
        while (now < start + e.duration()) {
            output.gain(e.last());
            1::samp => now;
        }
        
        <<< "Done with envelope" >>>;
    }
}

// Looping functionality
class Loop {
    
    // State & instance variables
    int isRecording;
    int isPlaying;
    time startRecordingTime;
    
    Gain pre;
    Gain output;
    LiSa looper;
    SndBuf buf;

    // Effects (not wired into patch initially)
    DelayA delay;
    Granular granular;
    NRev reverb;
    
    // Patch
    looper => reverb => pre => output => dac;
    
    // Setup
    DEFAULT_REVERB => reverb.mix;
    MAX_GRANULAR_DURATION => granular.duration;
    DEFAULT_GRANULAR_GAIN => granular.out.gain;
    DEFAULT_DELAY_GAIN => delay.gain;
    MAX_DELAY => delay.max;
    MAX_DELAY => delay.delay;
    DEFAULT_GAIN => output.gain;
        
    fun void setupLoop(string filename) {
        filename => buf.read;
        
        // Set LiSa buffer size to sample size
        buf.samples() * 1::samp => looper.duration;
                
        // Transfer values from SndBuf to LiSa
        for (0 => int i; i < buf.samples(); i++) {
            looper.valueAt(buf.valueAt(i), i::samp);
        }
    }
    
    // Instance methods
    fun void startPlaying() {
        1 => isPlaying;
        while (isPlaying) {
            1 => looper.play;
            looper.duration() => now;
        }
    }
    
    fun void stopPlaying() {
        0 => isPlaying;
        0 => looper.play;
    }
}

class Controller {
    Loop loops[LOOP_COUNT];
    
    PedalBoard board;
    
    int activePedal;
    int activeTrack;
    
    fun void setup() {
        board.setup();
        
        loops[0].setupLoop("loop0-mono.wav");
        loops[1].setupLoop("loop1-mono.wav");
        loops[2].setupLoop("loop2-mono.wav");
        loops[3].setupLoop("loop0-mono.wav");
        
        spork ~ goPedal();
        spork ~ goExpression();
    }
    
    fun void clearEffects(int activeTrack) {
        // Clear delay and granular
        if (loops[activeTrack].isPlaying) {
            loops[activeTrack].output =< loops[activeTrack].delay;
            loops[activeTrack].delay =< loops[activeTrack].output;
            
            loops[activeTrack].pre =< loops[activeTrack].granular.in; 
            loops[activeTrack].granular.out =< loops[activeTrack].output;      
            loops[activeTrack].pre => loops[activeTrack].output;
        } else {
            output =< delay;
            delay =< output; 
            
            pre =< granular.in;     
            granular.out =< output;  
            pre => output;
        }
                
        <<< "Clear effects", activeTrack >>>;
    }
    
    fun void goPedal() {
        while (true) {
            board.pedalEvent => now;
            
            board.pedalEvent.pedal => activePedal;
            board.pedalEvent.track => activeTrack;
            
            // First row of pedals controls looping...
            //  *** Start playing
            if (activePedal == 0) {
                spork ~ loops[activeTrack].startPlaying();
                <<< "Start playing", activeTrack >>>;
            }
            
            // *** Stop playing
            if (activePedal == 1) {
                loops[activeTrack].stopPlaying();
                <<< "Stop playing", activeTrack >>>;
            }
            
            // *** Start big crescendo on all tracks
            if (activePedal == 2) {
                for (0 => int i; i < 3; i++) {
                    Env e;
                    
                    DUR_BIG_CRESCENDO => e.duration;
                    START_BIG_CRESCENDO => e.value;
                    END_BIG_CRESCENDO => e.target;
                    
                    spork ~ e.go(loops[i].output);
                }
                
                1 => didBigCrescendo;
                
                <<< "Start crescendo" >>>;
            }
            
            // *** Start small crescendo on all tracks
            if (activePedal == 3) {
                for (0 => int i; i < 3; i++) {
                    Env e;
                    
                    DUR_SMALL_CRESCENDO => e.duration;
                    START_SMALL_CRESCENDO => e.value;
                    END_SMALL_CRESCENDO => e.target;
                    
                    spork ~ e.go(loops[i].output);
                }
                
                0 => didBigCrescendo;
                
                <<< "Start small crescendo" >>>;
            }
            
            // *** Start decrescendo on all tracks
            if (activePedal == 4) {
                for (0 => int i; i < LOOP_COUNT; i++) {
                    Env e;
                    
                    DUR_SMALL_DECRESCENDO => e.duration;
                    
                    if (didBigCrescendo) {
                        <<< "Big" >>>;
                        START_SMALL_DECRESCENDO_FIRST => e.value;
                    } else {
                        <<< "Small" >>>;
                        START_SMALL_DECRESCENDO_SECOND => e.value;
                    }
                    
                    END_SMALL_DECRESCENDO => e.target;
                    
                    spork ~ e.go(loops[i].output);
                }
                
                <<< "Start descrescendo" >>>;
            }
                      
            // Second row of pedals controls effects...
            // *** Clear patch (no effects)
            if (activePedal == 5) {
                clearEffects(activeTrack);
            }
            
            // *** Delay
            if (activePedal == 6) {
                // If we have a loop playing, change patch for looper
                if (loops[activeTrack].isPlaying) {
                    // Disconnect if already connected first...
                    loops[activeTrack].output =< loops[activeTrack].delay =< loops[activeTrack].output;
                    loops[activeTrack].output => loops[activeTrack].delay => loops[activeTrack].output;
                } else {
                    // Disconnect if already connected first...
                    output =< delay =< output;
                    output => delay => output;
                }
                                
                <<< "Set delay", activeTrack >>>;
            }
            
            // *** Granular
            if (activePedal == 7) {                                
                // If we have a loop playing, change patch for looper
                if (loops[activeTrack].isPlaying) {
                    <<< "SEtting on track" >>>;
                    // Disconnect if already connected first...
                    loops[activeTrack].pre =< loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out =< loops[activeTrack].output;

                    // Connect Granular I/O to rest of patch
                    loops[activeTrack].pre =< loops[activeTrack].output; 
                    loops[activeTrack].pre => loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out => loops[activeTrack].output;
                } else {
                    // Do the same for direct input
                    pre =< granular.in;     
                    granular.out =< output; 
                    
                    pre =< output;
                    pre => granular.in;     
                    granular.out => output;                                    
                }
                
                <<< "Set granular", activeTrack >>>;
            }
            
            // *** Track Select
            if (activePedal == 9) {
                <<< "Selected track", activeTrack >>>;
            }
        }
    }
    
    fun void goExpression() {
        while (true) {
            board.expressionEvent => now;
            
            if (board.expressionEvent.pedal == 0) {
                Math.pow(board.expressionEvent.value, 4.0) => float gain;
                gain => loops[activeTrack].output.gain;
                gain => output.gain;
            }
            
            if (board.expressionEvent.pedal == 1) {
                Math.pow(board.expressionEvent.value, 4.0) => float control;
                
                // *** Delay
                MAX_DELAY * control => dur d;
                if (d < MIN_DELAY) {
                    MIN_DELAY => d;
                }
                
                if (loops[activeTrack].isPlaying) {
                    d => loops[activeTrack].delay.delay;
                } else {
                    d => delay.delay;
                }
                //<<< "Delay", d,  activeTrack >>>;
                
                // *** Granular sampling and synthesis
                MAX_GRANULAR_DURATION * control => d;
                if (d < MIN_GRANULAR_DURATION) {
                    MIN_GRANULAR_DURATION => d;
                }
                
                if (loops[activeTrack].isPlaying) {
                    d => loops[activeTrack].granular.duration;
                } else {
                    d => granular.duration;
                }
                //<<< "Granular", d, activeTrack >>>;
            }
        }
    }
}

Controller c;

c.setup();

1::day => now;
