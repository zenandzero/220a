// same as hw4-3chaotic.ck but write data points to a file 
// see https://en.wikipedia.org/wiki/Logistic_map

// write data points to plot
"/tmp/tmp.dat" => string foutName;
// plot results in spreadsheet or with this command after shredding
// gnuplot -p -e "plot '/tmp/tmp.dat' w l"
// get gnuplot from http://gnuplot.sourceforge.net/

FileIO fout;
fout.open(foutName,FileIO.WRITE);
100 => int dataPts;

class Logistic
{
    float _x, _r;
    false => int isSet;
    fun void set( float x, float r )
    {
        x => _x;
        r => _r;
        true => isSet;
    }
    fun float tick( )
    {
        if (!isSet) 
        {
            <<<"Logistic not set, quitting","\ntry adding something like... 
            <your_obj>.set(0.7, 3.1); 
            // for initial x value and r coefficient">>>;
            me.exit();
        }
        (_r * _x) * (1.0 - _x) => _x;
        return _x;
    }
}
Logistic map;
map.set(0.7, 3.99);
for (0 => int i; i<dataPts; i++) 
{
    map.tick() => float tmp;
    <<<i, tmp>>>;
    fout <= tmp;
    fout <= "\n";
}
fout.close();
<<<"wrote",dataPts,"data points into",foutName>>>;
