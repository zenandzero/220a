/*adc => NRev r => Echo e => dac;
r.mix(0.5);

while (true) {

1::second => now;

}
*/

adc => NRev r => Gain delete => dac;
delete => DelayA delay => delete;

0.05 => r.mix;

0.5::second => dur d;

d => delay.max;
d => delay.delay;

0.8 => delay.gain;

1::day => now;
