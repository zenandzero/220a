// hook a mic to speaker through chuck
// test with different number of frames-per-period in qjackctl
// 1024 = obvious lag from mic
// 128 = not obvious

adc.chan(0) => Gain inGain => dac.chan(0); // always connect through a separate UG
while( true ) 1::samp => now;
