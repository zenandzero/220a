// Constants

3.::second => dur DEFAULT_DELAY;

// Main monitor patch

adc => NRev r => Gain output => dac;
DelayA delay;

r.mix(0.2);

// Looping functionality
class Loop {
    
    // State & instance variables
    int isRecording;
    int isPlaying;
    time startRecordingTime;
    
    // Patch
    adc => LiSa looper => NRev r => Gain output => dac;
    r.mix(0.01);
    
    // Effects (not wired into patch initially)
    DelayA delay;
    
    // Configuration
    10 => looper.maxVoices;
    60::second => looper.duration;
        
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
            
            // Second row of pedals controls looping...
            // *** Granular sampling and synthesis
            if (activePedal == 5) {
                <<< "Granular", activeTrack >>>;
            }
            
            // *** Delay
            if (activePedal == 6) {
                
                // If we have a loop playing, change patch for looper
                if (loops[activeTrack].isPlaying) {
                    loops[activeTrack].output => loops[activeTrack].delay => loops[activeTrack].output;
                    
                    0.8 => delay.gain;

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
           
        }
    }
    
    fun void goExpression() {
        while (true) {
            board.expressionEvent => now;
            
            if (board.expressionEvent.pedal == 0) {
                <<< "Gain ", board.expressionEvent.value >>>;
                
                
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
                    
                    DEFAULT_DELAY * board.expressionEvent.value => dur d;
                    
                    d => delay.max;
                    d => delay.delay;
                    
                    <<< "Delay", d,  activeTrack >>>;
                }
                
            }
        }
    }
}

// * START STUFF
/*
fun void increaseRate() {
    while (true) {
     loops[0].looper.rate() => float rate;
     rate + .1 => loops[0].looper.rate;
     
     2::second => now;   
    }
}*/

Controller c;

c.setup();
    
1::day => now;