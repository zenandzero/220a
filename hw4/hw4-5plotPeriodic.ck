// observe a low frequency periodic signal suitable for
// varying coefficients 

// write data points to plot
"/tmp/tmp.dat" => string foutName;
// plot results with this command after shredding
// gnuplot -p -e "plot '/tmp/tmp.dat' w l"

FileIO fout;
fout.open(foutName,FileIO.WRITE);
100 => int dataPts;

class Periodic
{
    TriOsc osc => Gain out => blackhole; // could be Sin, Saw, etc.
    Step unity => out;
    float _f, _a;
    false => int isSet;
    fun void set( float f, float a )
    {
        f => _f;
        a => _a;
        osc.freq(f);
        out.gain(0.5);
        true => isSet;
    }
    fun float tick( )
    {
        if (!isSet) 
        {
            <<<"Periodic not set, quitting","\ntry adding something like... 
            <your_obj>.set(1.0, 1.0); 
            // for initial freq and amp">>>;
            me.exit();
        }
        return out.last();
    }
}
Periodic wav;
wav.set(1.0, 1.0);
for (0 => int i; i<dataPts; i++) 
{
    wav.tick() => float tmp;
    <<<i, tmp>>>;
    fout <= tmp;
    fout <= "\n";
    100::ms => now; // next data point in time
}
fout.close();
<<<"wrote",dataPts,"data points into",foutName>>>;
