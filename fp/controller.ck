// Constants

3.::second => dur DEFAULT_DELAY;
0.05 => float DEFAULT_REVERB;
100::ms => dur DEFAULT_GRANULAR_DURATION;

// Main monitor patch

adc => NRev r => Gain output => dac;

DelayA delay;
Granular granular;

DEFAULT_REVERB => r.mix;
DEFAULT_GRANULAR_DURATION => granular.duration;

// Looping functionality
class Loop {
    
    // State & instance variables
    int isRecording;
    int isPlaying;
    time startRecordingTime;
    
    // Patch
    adc => LiSa looper => NRev r => Gain output => dac;
    
    // Effects (not wired into patch initially)
    DelayA delay;
    Granular granular;
    
    // Setup
    
    DEFAULT_REVERB => r.mix;
    DEFAULT_GRANULAR_DURATION => granular.duration;
        
    10 => looper.maxVoices;
    60::second => looper.duration;
    
    // Instance methods
    
    fun void startRecording() {
        if (!isRecording) {
            looper.clear(); // maximum of 1 voice for now
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
        } else {
            <<< "Not playing" >>>;
        }
        
        looper.clear();
    }
    
    fun void startPlaying(dur duration) {        
        looper.getVoice() => int voice;    
        looper.rate(voice, 1);
        
        1 => isPlaying;
        while (isPlaying) {
            looper.playPos(voice, 0::ms);
            looper.play(voice, 1);
            duration => now;
        }
    }
    
    fun void stopPlaying() {
        0 => isPlaying;
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
            
            // Second row of pedals controls effects...
            // *** Clear patch (no effects)
            if (activePedal == 5) {
                <<< "Granular", activeTrack >>>;
            }
            
            // *** Delay
            if (activePedal == 6) {
                // If we have a loop playing, change patch for looper
                if (loops[activeTrack].isPlaying) {
                    loops[activeTrack].output => loops[activeTrack].delay => loops[activeTrack].output;
                    
                    0.8 => loops[activeTrack].delay.gain;
                }
                
                // Otherwise, change direct adc => dac patch
                if (!loops[activeTrack].isPlaying) {
                    output => delay => output;
                    
                    0.8 => delay.gain;
                }
                
                DEFAULT_DELAY => delay.max;
                DEFAULT_DELAY => delay.delay;
                
                <<< "Delay", activeTrack >>>;
            }
            
            // *** Granular
            if (activePedal == 7) {
                // If we have a loop playing, change patch for looper
                if (loops[activeTrack].isPlaying) {
                    
                    // Disconnect from dac
                    loops[activeTrack].output =< dac;
                    
                    // Connect Granular I/O to rest of patch.
                    loops[activeTrack].output => loops[activeTrack].granular.in; 
                    loops[activeTrack].granular.out => dac;
                    
                }
                
                // Otherwise, change direct adc => dac patch
                if (!loops[activeTrack].isPlaying) {
                    // Disconnect from dac
                    output =< dac;
                    
                    // Connect Granular I/O to rest of patch.
                    output => granular.in;     
                    granular.out => dac;                                    
                    
                }
                
                <<< "Granular", activeTrack >>>;
            }
        }
    }
    
    fun void goExpression() {
        while (true) {
            board.expressionEvent => now;
            
            if (board.expressionEvent.pedal == 0) {
                <<< "Gain ", board.expressionEvent.value >>>;
                
                // TODO: scale logarithmcally, set min and max
                board.expressionEvent.value => output.gain;
            }
            
            if (board.expressionEvent.pedal == 1) {
                <<< "Control ", board.expressionEvent.value >>>;
                
                // *** Granular sampling and synthesis
                if (activePedal == 5) {
                    <<< "Granular", activeTrack >>>;
                }
                
                // *** Delay
                if (activePedal == 6) {
                    
                    // TODO: set min and max delays
                    DEFAULT_DELAY * board.expressionEvent.value => dur d;
                    
                    d => delay.max;
                    d => delay.delay;
                    
                    <<< "Delay", d,  activeTrack >>>;
                }
                
            }
        }
    }
}


Controller c;

c.setup();

1::day => now;