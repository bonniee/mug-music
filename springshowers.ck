//******************************************************************
// Bonnie Eisenman (bmeisenm@)
// Harvest Zhang (hlzhang@)
// 9 March 2014
// 
// This is an atmospheric instrument that puts us in the middle of
// a spring thunderstorm. Set up the Arduino, place one end of the
// alligator clip in a nearly full mug or glass of water, and try
// different things! Touch the mug, wrap your fingers around it, dip
// a finger into the mug, touch a grounded object (like a laptop)
// while dipping a finger in the mug. Listen for peals of thunder
// and the gentle ringing of chimes, both in a whole-tone scale in the
// mid range as well as chromatically in the high range.
//
// Run as: chuck springshowers.ck: [serialport]
//******************************************************************

SerialIO.list() @=> string list[];

for(int i; i < list.cap(); i++)
{
    chout <= i <= ": " <= list[i] <= IO.newline();
}

// parse first argument as device number
0 => int device;
if(me.args()) {
    me.arg(0) => Std.atoi => device;
}

if(device >= list.cap())
{
    cherr <= "serial device #" <= device <= " not available\n";
    me.exit(); 
}

SerialIO cereal;
if(!cereal.open(device, SerialIO.B9600, SerialIO.ASCII))
{
	chout <= "unable to open serial device '" <= list[device] <= "'\n";
	me.exit();
}


Mug muggy;
Storm storm;

while(true)
{
    cereal.onLine() => now;
    cereal.getLine() => string line;
    if(line$Object != null) {
        //chout <= "line: " <= line <= IO.newline();
        StringTokenizer tok;
        tok.set(line);
        Std.atoi(tok.next()) => int pos;
        Std.atoi(tok.next()) => int val;
        muggy.play(pos);
        storm.play(pos);
        
    }
}

class Storm {
    string rainFile;
    me.sourceDir() + "/rainloop.wav" => rainFile;
    me.sourceDir() + "/thunderstrike.wav" => string thunderFile;
    SndBuf rainBuf => Gain rainGain => dac;


    rainFile => rainBuf.read;
    0.5 => rainBuf.gain;
    1.0 => rainBuf.rate;
    true => rainBuf.loop;
    rainGain.gain(1.0);

    0 => int lastVal;
    80 => int loudThresh;
    5 => int lowThresh;

    fun void play(int val) {
        if (shouldThunderStrike(val)) {
            spork~ playThunder();
            chout <= "Sporked thunder" <= IO.newline();
        }
        // Uncomment to re-enable rain volume fade
        //normalize(val) => float volume;
        //chout <= "rain volume: " <= volume <= IO.newline();
        //volume => rainBuf.gain;
        val => lastVal;
    }

    fun float normalize(int val) {
        40.0 => float highVal;
        20.0 => float lowVal;

        if (val > highVal) {
            return 1.0;
        }
        else {
            return (val - lowVal) / (highVal - lowVal);
        }
    }

    fun int shouldThunderStrike(int val) {
        if ((val > loudThresh || val < lowThresh) &&
            !(lastVal > loudThresh || lastVal < lowThresh)) {
            return true;
        }
        else return false;
    }

    fun void playThunder() {
        Math.random2(1,3) => int randPick;
        me.sourceDir() + "/thunder" + randPick + ".wav" => string thunderFile;
        SndBuf buf  => dac;
        thunderFile => buf.read;
        1.0 => buf.rate;
        0.8 => buf.gain;
        buf.length() => now;
        chout <= "Done thundering";
    }
}


class Mug {

    SinOsc c;
    ADSR env; 
    PRCRev reverb;
    Gain g;

    c => env => reverb => g => dac;
    g.gain(1);
    env.set(10::ms, 200::ms, 0.5, 100::ms);
    0 => int lastVal;

    fun void play(int val) {
        chout <= "Raw: " <= val <= " Scaled: ";

        // Loitering reading
        if (val < 29) {
            env.keyOff();
        }
        else { 
            // Super high frequencies — caused by touching laptop & water
            if (val > 80) {
                val - 60 => val;
            }
            // Other frequency
            else if (29 <= val && val < 48) {
                // TODO add a little delay
                (val * 2) + 0 => val;
            }
            else {
                val + 30 => val;
            }
            if (val != lastVal) {
                env.keyOff();
                10::ms => now;
                env.keyOn();
            }
        }
        
        c.freq(Std.mtof(val));
        val => lastVal;
        chout <= val <= IO.newline();

    }
}