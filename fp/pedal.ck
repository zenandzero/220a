
public class PedalBoard {
    MidiIn events;
    PedalEvent pedalEvent;
    ExpressionPedalEvent expressionEvent;
    
    fun void setup() {
        // open the device
        if (events.open(0)) {
            <<< "device", events.name(), "->", "open: SUCCESS" >>>;
            spork ~ go(events);
        }
    }
    
    fun void go(MidiIn min) {
       MidiMsg msg;
       
       while (true) {
           // wait on event
           min => now;
           
           // print message
           while(min.recv(msg))
           {
               // print out midi message with id
               //<<< msg.data1, msg.data2, msg.data3 >>>;
               
               // Pedal clicked
               if (msg.data1 == 192) {
                   
                   // data2 tells us the pedal and track that were selected
                   //
                   // there are 10 pedals and 10 tracks, numbered 0 to 9
                   // the first digit gives us the pedal
                   // the second digit give us the track
                   // for example...
                   //
                   // 29 represents a click on pedal track 2 and pedal 9
                   
                   msg.data2 % 10 => int pedal;
                   msg.data2 / 10 => int track;
                   
                   //<<< "Pedal", pedal >>>;
                   //<<< "Track", track >>>;
                   
                   pedal => pedalEvent.pedal;
                   track => pedalEvent.track;
                   
                   pedalEvent.signal();
               }
               
               // Expression pedal used
               if (msg.data1 == 176) {
                   
                   // Left pedal
                   if (msg.data2 == 27) {
                       0 => expressionEvent.pedal;
                   }
                   
                   // Right pedal
                   if (msg.data2 == 7) {
                       1 => expressionEvent.pedal;
                   }
                   
                   msg.data3 / 127. => expressionEvent.value;
                   expressionEvent.signal();
               }
           }
       }
   }
}