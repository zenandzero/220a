// chuck probeHID.ck
// probe HID's

// ok for macs and CCRMA linux desktops

// for linux laptops, connect the device
// then get permission for all input devices
// which requires sudo or root privileges
// sudo chmod a+r /dev/input/event*
// after which you need to quit and restart miniAudicle if already running

// choose type of device desired in the while loop below
// check for kbd 
//  hid.openKeyboard(dev) 
// or
// check for gameTrak
//  hid.openJoystick(dev) 


Hid hid;
true => int devIsOK;
0 => int dev;
100 => int devsToTest; // some large number
while (devIsOK && (dev < devsToTest)) {
  hid.openKeyboard(dev) => devIsOK;	// for kbd device
 // hid.openJoystick(dev) => devIsOK;	// for Gametrak
  if (devIsOK) {
    <<< dev, hid.name(), "ready">>>;
    dev++;
  }
}
    <<<"...so exactly",dev,"devices are available numbered from 0">>>;

// example output from fedora 28 on Lenovo P51
// in this case, 11 is the keyboard for kbd.ck example
/*
0 HDA Intel PCH HDMI/DP,pcm=10 ready 
1 HDA Intel PCH HDMI/DP,pcm=9 ready 
2 HDA Intel PCH HDMI/DP,pcm=8 ready 
3 HDA Intel PCH HDMI/DP,pcm=7 ready 
4 HDA Intel PCH HDMI/DP,pcm=3 ready 
5 HDA Intel PCH Headphone ready 
6 HDA Intel PCH Dock Headphone ready 
7 HDA Intel PCH Dock Mic ready 
8 HDA Intel PCH Mic ready 
9 Integrated Camera: Integrated C ready 
10 ThinkPad Extra Buttons ready 
11 Video Bus ready 
12 Video Bus ready 
13 AT Translated Set 2 keyboard ready 
14 Power Button ready 
15 Lid Switch ready 
16 Sleep Button ready 
[probeHID.ck]: HidIn: couldn't open keyboard 17...
...so exactly 17 devices are available numbered from 0 
*/
