// Constants

4.::second => dur MAX_DELAY;
500::samp => dur MIN_DELAY;
0.5 => float DEFAULT_DELAY_GAIN;

0.001 => float DEFAULT_REVERB;

150::ms => dur MAX_GRANULAR_DURATION;
1::ms => dur MIN_GRANULAR_DURATION;

// Main monitor patch

adc => NRev r => Gain output => dac;

DelayA delay;
Granular granular;

DEFAULT_REVERB => r.mix;
MAX_GRANULAR_DURATION => granular.duration;
DEFAULT_DELAY_GAIN => delay.gain;
MAX_DELAY => delay.max;
MAX_DELAY => delay.delay;

// Looping functionality
class Loop {
    
    // State & instance variables
    int isRecording;
    int isPlaying;
    time startRecordingTime;
    
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
        
        DEFAULT_REVERB => r.mix;
        
        adc => looper => reverb => output => dac;
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
    Loop loops[9];
    
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
            
            loops[activeTrack].output =< loops[activeTrack].granular.in; 
            loops[activeTrack].granular.out =< dac;      
            loops[activeTrack].output => dac;
        } else {
            output =< delay;
            delay =< output; 
            
            output =< granular.in;     
            granular.out =< dac;  
            output => dac;
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
                    // Disconnect from dac
                    loops[activeTrack].output =< dac;
                    loops[activeTrack].output =< loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out =< dac;

                    // Connect Granular I/O to rest of patch
                    loops[activeTrack].output => loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out => dac;
                } else {
                    // Do the same for direct input
                    output =< dac;
                    output =< granular.in;     
                    granular.out =< dac; 
                    
                    output => granular.in;     
                    granular.out => dac;                                    
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
                
                if (loops[activeTrack].isPlaying) {
                    gain => loops[activeTrack].output.gain;
                }
                
                // Always modulate direct output
                gain => output.gain;
                
                //<<< "Gain", gain >>>;
            }
            
            if (board.expressionEvent.pedal == 1) {
                Math.pow(board.expressionEvent.value, 2.0) => float control;

                //<<< "Control ", board.expressionEvent.value >>>;
                
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
                    
                    //<<< "Delay", d,  activeTrack >>>;
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
