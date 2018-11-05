// print values from chaotic function suitable for
// varying coefficients to console window
// see https://en.wikipedia.org/wiki/Logistic_map

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
map.set(0.7, 3.1);
for (0 => int i; i<100; i++) <<<map.tick()>>>;
