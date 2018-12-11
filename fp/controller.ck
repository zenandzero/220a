// Constants

0.1 => float DEFAULT_GAIN;

4::second => dur MAX_DELAY;
40::ms => dur MIN_DELAY;
0.8 => float DEFAULT_DELAY_GAIN;

0.02 => float DEFAULT_REVERB;

150::ms => dur MAX_GRANULAR_DURATION;
1::ms => dur MIN_GRANULAR_DURATION;

9 => int LOOP_COUNT;

// Main monitor patch

adc => NRev r => Gain pre => Gain output => dac;

DelayA delay;
Granular granular;

DEFAULT_REVERB => r.mix;
MAX_GRANULAR_DURATION => granular.duration;
DEFAULT_DELAY_GAIN => delay.gain;
MAX_DELAY => delay.max;
MAX_DELAY => delay.delay;

DEFAULT_GAIN => output.gain;

class Env {
    Step s => Envelope e => blackhole;
    fun void target(float val) { e.target(val); }
    fun void go(UGen output) {
        now => time start;
        while (now < start + e.duration()) {
            output.gain(e.last());
            1::samp => now;
        }
        
        <<< "End of crescendo" >>>;
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
    DEFAULT_DELAY_GAIN => delay.gain;
    MAX_DELAY => delay.max;
    MAX_DELAY => delay.delay;
        
    fun void setupLoop(string filename) {
        filename => buf.read;
        
        // Set LiSa buffer size to sample size
        buf.samples() * 1::samp => lisa.duration;
        
        // Transfer values from SndBuf to LiSa
        for (0 => int i; i < buf.samples(); i++) {
            looper.valueAt(buf.valueAt(i), i::samp);
        }
    }
    
    // Instance methods
    fun void startPlaying(dur duration) {        
        looper.getVoice() => int voice;
        looper.rate(voice, 1);
                
        1 => isPlaying;
        while (isPlaying) {
            looper.playPos(voice, 0::ms);
            looper.play(voice, 1);
            looper.duration() => now;
        }
    }
    
    fun void stopPlaying() {
        0 => isPlaying;
    }
}

class Controller {
    Loop loops[LOOP_COUNT];
    
    PedalBoard board;
    
    int activePedal;
    int activeTrack;
    
    fun void setup() {
        board.setup();
        
        loops[0].setupLoop("loop0.wav");
        loops[1].setupLoop("loop1.wav");
        loops[2].setupLoop("loop2.wav");
        
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
                loops[activeTrack].startPlaying();
                <<< "Start playing", activeTrack >>>;
            }
            
            // *** Stop playing
            if (activePedal == 1) {
                loops[activeTrack].stopPlaying();
                <<< "Stop playing", activeTrack >>>;
            }
            
            // *** Start big crescendo on all tracks
            if (activePedal == 2) {
                for (0 => int i; i < LOOP_COUNT; i++) {
                    Env e;
                    20::second => e.e.duration;
                    
                    0.1 => e.e.value;
                    0.9 => e.target;
                    spork ~ e.go(loops[i].output);
                }
                
                <<< "Start crescendo" >>>;
            }
            
            // *** Start small crescendo on all tracks
            if (activePedal == 3) {
                for (0 => int i; i < LOOP_COUNT; i++) {
                    Env e;
                    10::second => e.e.duration;
                    
                    0 => e.e.value;
                    0.2 => e.target;
                    spork ~ e.go(loops[i].output);
                }
                
                <<< "Start small crescendo" >>>;
            }
            
            // *** Mute all tracks
            if (activePedal == 4) {
                for (0 => int i; i < LOOP_COUNT; i++) {
                    0 => loops[i].output.gain;
                }
                
                <<< "Mute" >>>;
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
                    // Disconnect if already connected first...
                    loops[activeTrack].pre =< loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out =< loops[activeTrack].output;

                    // Connect Granular I/O to rest of patch
                    loops[activeTrack].pre =< loops[activeTrack].output; 
                    loops[activeTrack].pre => loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out => loops[activeTrack].output;
                } else {
                    // Do the same for direct input
                    pre =< output;
                    pre =< granular.in;     
                    granular.out =< output; 
                    
                    pre => granular.in;     
                    granular.out => output;                                    
                }
                
                <<< "Set granular", activeTrack >>>;
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
                <<< "Delay", d,  activeTrack >>>;
                
                // *** Granular sampling and synthesis
                MAX_GRANULAR_DURATION * control => dur d;
                if (d < MIN_GRANULAR_DURATION) {
                    MIN_GRANULAR_DURATION => d;
                }
                
                if (loops[activeTrack].isPlaying) {
                    d => loops[activeTrack].granular.duration;
                } else {
                    d => granular.duration;
                }
                <<< "Granular", d, activeTrack >>>;
            }
        }
    }
}

Controller c;

c.setup();

1::day => now;
