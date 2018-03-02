# MEGAPi
Assorted documentation for setting up a Raspberry Pi Zero W as a WiFi hotspot with 3G connectivity for our Chromecast-enabled MEGABoominator project.

The project is using a Raspberry Pi Zero W (but other flavors of Pi should work) running Raspbian Stretch Lite (Version November 2017 as of March 2nd 2018). The repository contains a "*modified*" version of the Raspbian image for easily getting the project up and running as we need it. It requires an 8GB SD card because that's what i'm using ¯\\\_(ツ)_/¯

**These changes are:**

* Locale changed to `en_DK`
* Keyboard layout set to `danish`
* SSH enabled (with my public key added ᕕ( ᐛ )ᕗ)
* Wi-Fi Country set to `Denmark`
* Hostname set to `MEGAPi`
* Filesystem expanded
* `ACT Led` set to always be off

It's probably also a good things to do the following after installing:
* Change root password

## Software
* Hostapd

## Resources
* https://www.raspberrypi.org/forums/viewtopic.php?f=38&t=50543
* https://learn.adafruit.com/setting-up-a-raspberry-pi-as-a-wifi-access-point/install-software
* http://blog.pi3g.com/2014/04/make-raspbian-system-read-only/
* https://petr.io/en/blog/2015/11/09/read-only-raspberry-pi-with-jessie/