# MEGAPi V2

### **A simplified version without much of the jank**

Assorted documentation for setting up a Raspberry Pi Zero W as a WiFi hotspot with 3G connectivity for our Chromecast-enabled MEGABoominator project.

The project is using a Raspberry Pi 3 Model B+ (but other flavors of Pi will probably work) running Raspbian Stretch Lite (Version `April 2019` as of May 11th 2019)

**Table of Content**
* [Raspbian](#raspbian)
* [Software](#software)
* [Static IP](#static-ip)
* [Configuring DHCP](#configuring-dhcp)
* [Configuring AP](#configuring-ap)
* [3G Connectivity](#3g-connectivity)
* [Network Address Translation](#network-address-translation)
* [Statistics](#statistics)
* [Handle Power Loss](#handle-power-loss)
* [Power Saving](#power-saving)
* [Resources](#resources)

## Raspbian
The base image of the Raspbian OS has had the following changes made before starting the actual project

* Locale changed to `en_DK`
* Keyboard layout set to `danish`
* SSH enabled (with my public key added ᕕ( ᐛ )ᕗ)
* Wi-Fi Country set to `Denmark`
* Hostname set to `MEGAPi`
* Filesystem expanded
* `ACT ` and `PWR` LEDs permanently turned off

It's probably also a good idea to do the following after installing:
* Change root password

Download the modified base image: [megapi_raspbian_2019_04_08_base.dmg](http://mega.re/public/megapi_raspbian_2019_04_08_base.dmg)   
Downloading the finished image: [megapi_raspbian_2019_04_08_full.dmg](http://mega.re/public/megapi_raspbian_2019_04_08_base.dmg)

## Software
* hostapd
* dnsmasq
* iptables-persistent

Install the software required for networking
```
sudo apt install hostapd dnsmasq
```

Stop `hostapd and dnsmasq` services
```
sudo systemctl stop dnsmasq
sudo systemctl stop hostapd
```

## Static IP
```
sudo nano /etc/dhcpcd.conf
```

and add the following to set a static IP for `wlan0`

```
#Set static ip for wlan0
interface wlan0
  static ip_address=10.0.0.1/24
```

Restart `dhcpcd`
```
sudo service dhcpcd restart
```

## Configuring DHCP
Edit the `dnsmasq` config

```
sudo nano /etc/dnsmasq.conf
```

and add the following to setup DHCP

```
interface=wlan0
  dhcp-range=10.0.0.10,10.0.0.254,255.255.255.0,24h
  dhcp-option=6,1.1.1.1,1.0.0.1
```
This will provide addresses in the range `10.0.0.10` to `10.0.0.254` with a lease time of 24 hours and set `1.1.1.1` and `1.0.0.1` as DNS servers.

## Configuring AP
Edit the `hostapd` config
```
sudo nano /etc/hostapd/hostapd.conf
```

and add the following to setup the AP

```
#Set interface
interface=wlan0

#Interface driver
driver=nl80211

#Enable 802.11g
hw_mode=g

#Enable 802.11n
ieee80211n=1

#Something with QoS
wmm_enabled=1

#Set WiFi channel (0 for auto)
channel=11

#Set country (for channel regulation and such)
country_code=DK

#Enabled country
ieee80211d=1

#Set SSID
ssid=MEGABoominator

#Set WiFi password
wpa_passphrase=ThunderDucks

#Set security type (1 = WPA, 2 = WEP (NOOOOO) & 3 = Both)
auth_algs=1

#WPA2 only
wpa=2

#Use pre-shared key
wpa_key_mgmt=WPA-PSK

#Something with encryption protocols..
wpa_pairwise=CCMP TKIP
rsn_pairwise=CCMP

#Disbale MAC address filtering
macaddr_acl=0

```

tell the system where to find this configuration file

```
sudo nano /etc/default/hostapd
```

specify the path to the configuration file

```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

Start the services again
```
sudo systemctl start dnsmasq
sudo systemctl start hostapd
```

## 3G Connectivity
The Huawei E3372h should just work out of the box as `eth1`

## Network Address Translation
Edit `sysctl.conf`
```
sudo nano /etc/sysctl.conf
```

Add to the bottom:
```
net.ipv4.ip_forward=1
```

Also the following to activate it immediately
```
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
```

Install `iptables-persistent` to have the rules persist on reboot
```
sudo apt install iptables-persistent
```

To actually get an internet connection from the 3G modem when connected to the Pi via WiFi a connection between the two interfaces wlan0 and eth1 (the usb modem) needs to me established. This is done with iptables:

```
sudo iptables -t nat -A POSTROUTING -o eth1 -j MASQUERADE
sudo iptables -A FORWARD -i eth1 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o eth1 -j ACCEPT
```

To make this happen on reboot do
```
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
```

## Statistics
TODO: https://serverfault.com/questions/533513/how-to-get-tx-rx-bytes-without-ifconfig


## Handle Power Loss
A read only OS is a giant pain in the ass.   
TODO: https://raspi-ups.appspot.com/en/index.jsp

## Power Saving
We're out in the field - every mA counts!

Disable HDMI 
```
sudo nano /etc/rc.local
```
Add the following to disable HDMI. -p re-enables
```
/usr/bin/tvservice -o
```

Disbaled `ACT` and `PWR` LEDs
```
sudo nano /boot/config.txt
```

Add the following lines
```
# Disable the ACT LED
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on

# Disable the PWR LED
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off
```

## Resources
* https://raspberrypi.org/forums/viewtopic.php?f=38&t=50543
* https://raspberrypi.org/documentation/configuration/wireless/access-point.md
* https://learn.adafruit.com/setting-up-a-raspberry-pi-as-a-wifi-access-point/install-software
* https://jeffgeerling.com/blogs/jeff-geerling/raspberry-pi-zero-conserve-energy
* https://serverfault.com/questions/533513/how-to-get-tx-rx-bytes-without-ifconfig
* https://raspi-ups.appspot.com/en/index.jsp
