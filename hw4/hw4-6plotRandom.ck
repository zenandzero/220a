// observe a random walk suitable for
// varying coefficients 

// write data points to plot
"/tmp/tmp.dat" => string foutName;
// plot results with this command after shredding
// gnuplot -p -e "plot '/tmp/tmp.dat' w l"

FileIO fout;
fout.open(foutName,FileIO.WRITE);
100 => int dataPts;

class Random
{
    float _l, _h;
    false => int isSet;
    fun void set( float l, float h )
    {
        l => _l;
        h => _h;
        true => isSet;
    }
    fun float tick( )
    {
        if (!isSet) 
        {
            <<<"Periodic not set, quitting","\ntry adding something like... 
            <your_obj>.set(0.0, 1.0); 
            // for initial freq and amp">>>;
            me.exit();
        }
        return Std.rand2f(_l, _h);
    }
}
Random ran;
ran.set(0.0, 1.0);
for (0 => int i; i<dataPts; i++) 
{
    ran.tick() => float tmp;
    <<<i, tmp>>>;
    fout <= tmp;
    fout <= "\n";
}
fout.close();
<<<"wrote",dataPts,"data points into",foutName>>>;
