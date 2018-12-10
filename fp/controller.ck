// Constants

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
    LiSa @ looper;
    
    // Patch
    resetPatch();

    // Effects (not wired into patch initially)
    DelayA delay;
    Granular granular;
    
    // Setup
    MAX_GRANULAR_DURATION => granular.duration;
    DEFAULT_DELAY_GAIN => delay.gain;
    MAX_DELAY => delay.max;
    MAX_DELAY => delay.delay;
        
    fun void resetPatch() {
        new LiSa @=> looper;
        NRev reverb;
        
        DEFAULT_REVERB => reverb.mix;
        
        adc => looper => reverb => pre => output => dac;
        200 => looper.maxVoices;
        60::second => looper.duration;
        60::second => looper.loopEndRec;
        looper.clear();
    }
    
    // Instance methods   
    fun void startRecording() {
        if (!isRecording) {
            1 => looper.record;
            1 => isRecording;
            now => startRecordingTime;
        } else {
            <<< "Already recording" >>>;
        }
    }
    
    fun void stopRecording() {
        if (isRecording) {
            0 => looper.record;
            0 => isRecording;
            spork ~ startPlaying(now - startRecordingTime);
        } else {
            <<< "Not recording" >>>;
        }
    }
    
    fun void clearRecording() {
        if (isPlaying) {
            stopPlaying();
            resetPatch();
        } else {
            <<< "Not playing" >>>;
        }
    }
    
    fun void startPlaying(dur duration) {        
        looper.getVoice() => int voice;
        looper.rate(voice, 1);
                
        1 => looper.gain;
        1 => isPlaying;
        while (isPlaying) {
            looper.playPos(voice, 0::ms);
            looper.play(voice, 1);
            duration => now;
        }
    }
    
    fun void stopPlaying() {
        0 => isPlaying;
        0 => looper.gain;
    }
}

class Controller {
    Loop loops[LOOP_COUNT];
    
    PedalBoard board;
    
    int activePedal;
    int activeTrack;
    
    fun void setup() {
        board.setup();
        
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
            //  *** Start recording
            if (activePedal == 0) {
                loops[activeTrack].startRecording();
                <<< "Start recording", activeTrack >>>;
            }
            
            // *** Stop recording
            if (activePedal == 1) {
                loops[activeTrack].stopRecording();
                <<< "Stop recording", activeTrack >>>;
            }
            
            // *** Clear recording
            if (activePedal == 2) {
                loops[activeTrack].clearRecording();
                <<< "Clear recording", activeTrack >>>;
            }
            
            // *** Set active track
            if (activePedal == 3) {
                <<< "Active track", activeTrack >>>;
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
            
            // *** Start big crescendo on all tracks
            if (activePedal == 8) {
                for (0 => int i; i < LOOP_COUNT; i++) {
                    Env e;
                    1.5::minute => e.e.duration;
                    loops[i].output.gain() => e.e.value;
                    loops[i].output.gain() * 10 => e.target;
                    spork ~ e.go(loops[i].output);
                }
                
                <<< "Start crescendo" >>>;
            }
            
            // *** Start small crescendo on all tracks
            if (activePedal == 4) {
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
            if (activePedal == 9) {
                for (0 => int i; i < LOOP_COUNT; i++) {
                    0 => loops[i].output.gain;
                }
                
                <<< "Mute" >>>;
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
                if (activePedal == 6) {
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
                }
                
                // *** Granular sampling and synthesis
                if (activePedal == 7) {
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
}

Controller c;

c.setup();

1::day => now;
