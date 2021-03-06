# MEGAPi
Assorted documentation for setting up a Raspberry Pi Zero W as a WiFi hotspot with 3G connectivity for our Chromecast-enabled MEGABoominator project.

The project is using a Raspberry Pi 3 Model B (but other flavors of Pi will probably work) running Raspbian Stretch Lite (Version `April 2018` as of May 26th 2018)

**Table of Content**
* [Raspbian](#raspbian)
* [Software](#software)
* [Static IP](#static-ip)
* [Configuring DHCP](#configuring-dhcp)
* [Configuring AP](#configuring-ap)
* [DHCP Lease Hack](#dhcp-lease-hack)
* [3G Connectivity](#3g-connectivity)
* [Network Address Translation](#network-address-translation)
* [vnStat](#vnstat)
* [Read-only SD card](#read-only-sd-card)
* [Power Saving](#power-saving)
* [Resources](#resources)

## Raspbian
The base image of the Raspbian os has had the following changes made before starting the actual project

* Locale changed to `en_DK`
* Keyboard layout set to `danish`
* SSH enabled (with my public key added ᕕ( ᐛ )ᕗ)
* Wi-Fi Country set to `Denmark`
* Hostname set to `MEGAPi`
* Filesystem expanded
* `ACT Led` set to always be off

It's probably also a good idea to do the following after installing:
* Change root password

Download the modified base image
[MEGAPi_Raspbian-April2018_Base.img](https://israndom.win/megapi/MEGAPi_Raspbian-April2018_Base.img)   
Downloading the finished image
[MEGAPi_Raspbian-April2018_Finished.img](https://israndom.win/megapi/MEGAPi_Raspbian-April2018_Finished.img)

## Software
* hostapd
* dnsmasq
* wvdial
* ppp
* sg3-utils
* iptables-persistent
* dnsmasq-utils
* hostapd_cli
* vnstat

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
  dhcp-range=10.0.0.10,10.0.0.100,255.255.255.0,24h
  dhcp-option=wireless-net,3
  dhcp-option=wireless-net,6
```

**or**

```
interface=wlan0
  dhcp-range=10.0.0.10,10.0.0.100,255.255.255.0,24h
  dhcp-option=6,1.1.1.1,1.0.0.1
```
The first option will provide addresses in the range 10.0.0.10 to 10.0.0.100 with a lease time of 24 hours and prohibit sending DNS server options to the client - this is useful for allowing phones to connect to the network but still use cellular for data.   
The send option will do the same, but set `1.1.1.1` and `1.0.0.1` as DNS servers.

**or (the current working config used in the Boominator)**
```
# Setup DHCP for MEGAPi
interface=wlan0
  #DHCP Servers
  dhcp-option=6,1.1.1.1,1.0.0.1

  #DHCP Address Range
  dhcp-range=10.0.0.20,10.0.0.20,255.255.255.0,1h

  #Static IP Assingments
  dhcp-host=54:60:09:FC:47:A2,10.0.0.2 #Chromecast Audio
  #dhcp-host=,10.0.0.3 #ESP8266
  dhcp-host=F0:98:9D:D5:BC:AA,10.0.0.10 #Jacobs iPhone
  dhcp-host=00:24:D7:BA:10:68,10.0.0.11 #ITMDKLT027
  dhcp-host=DC:56:E7:A2:28:C5,10.0.0.12 #Pedes iPhone
```

This sets the DHCP as above but limits the DHCP range to a single IP and sets two static IP assignments.

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

#Required to make hostapd_cli work
ctrl_interface=/var/run/hostapd
ctrl_interface_group=0

```

tell the system where to find this configuration file

```
sudo nano /etc/default/hostapd
```

to specify the configuration file

```
DAEMON_CONF="/etc/hostapd/hostapd.conf"
```

Start the services again
```
sudo systemctl start dnsmasq
sudo systemctl start hostapd
```

## DHCP Lease Hack
The DHCP scope has previous been set to just a single address as we don't want more than the "DJ" using the WiFi and wasting our precious gigabytes.   
To achieve this we need to mess with the network and make sure that DHCP leases are released as soon as a client disconnects instead of having to wait for the lease time to expire.

Install `hostapd_cli` and `dnsmasq-utils` to get access to `dhcp_release`
```
sudo apt install hostapd_cli dnsmasq-utils
```

`dhcp_release` makes it possible to force dnsmasq to release a lease before the actual expiry time. Together with `hostapd_cli` it's possible to execute a script when a client disconnects and force release that clients lease:

```
#dhcp-release-script.sh
#!/bin/bash
#Chromecast, Jacob iPhone, ITMDKLT027
staticDevicesMac=("54:60:09:fc:47:a2" "f0:98:9d:d5:bc:aa" "00:24:d7:ba:10:68")

if [[ $2 == "AP-STA-DISCONNECTED" ]]
then
  if [[ ! " ${staticDevicesMac[@]} " =~ " ${3} " ]]
  then
    dhcp_release $1 10.0.0.20 $3
  fi
fi
```
The staticDevices is an array containing the MAC adresses of clients with static IPs that shouldn't trigger the dhcp_release-script.

Make the script executable
```
sudo chmod +x dhcp-release-script.sh
```

Create a new systemd-service to start hostapd_cli with the bash script:
```
sudo nano /etc/systemd/system/dhcp-release.service
```

with the follwing content

```
[Unit]
Description=Release DHCP lease on diconnect
After=hostapd

[Service]
Type=simple
ExecStartPre=/bin/sleep 15
ExecStart=/usr/sbin/hostapd_cli -a /home/pi/dhcp-release-script.sh
User=root
Group=root

[Install]
WantedBy=multi-user.target
```

The service waits 15 seconds before starting to make sure `hostapd` is running as the sevrice will fail otherwise.

Reload the systemctl daemon
```
sudo systemctl daemon-reload
```

Enable the service at startup
```
sudo systemctl enable dhcp-release.service
```

## 3G Connectivity
Install the remaining software
```
sudo apt install wvdial ppp sg3-utils insserv
```

Edit the `wvdial` config
```
sudo nano /etc/wvdial.conf
```

the following snippet will setup the modem to work with our Lebara cell plan. 

```
[Dialer Defaults]
Init1 = ATZ
Init2 = ATQ0 V1 E1 S0=0 &C1 &D2 +FCLASS=0
Init3 = AT+CGDCONT=1, "IP", "internet"

Modem Type = Analog Modem
ISDN = 0
NEW PPPD = yes
Username = dummy
Password = dummy
Modem = /dev/ttyUSB0
Dial Command = ATD
Stupid Mode = 1
Phone = *99#
Baud = 115200
```

`"internet"` needs to be set to the right `APN`:
>Replace YOUR_APN and the Phone entry by whatever is appropriate for your connection.  For Bell, the APN was pda.bell.ca.  One useful trick is (when the dongle is in modem mode) to run wvdialconf as a regular user (not root).  It will communicate with the usb serial and try out different options, reporting on the results of what works without actually changing the wvdial.conf file (since it should be owned by root).

Edit `wvdial`
```
sudo nano /etc/ppp/peers/wvdial
```

with the following because of reasons

```
noauth
local
name wvdial
usepeerdns
```

Add a new interface for the modem
```
sudo nano /etc/network/interfaces
```

by adding
```
#3G Modem
iface ppp0 inet wvdial
```

Download [autoconnect-1.0.zip](autoconnect-1.0.zip) and extract the contents to the appropriate locations
```
/etc
/etc/default/autoconnect
/etc/init.d/autoconnect
```

Edit the `autoconnect`-script in `/etc/default/autoconnect` and change values as required to fit the USB modem.

```
sudo nano /etc/default/autoconnect
```
```
# autoconnect params

# USB_ID -- the modem mode id we *want* to see with lsusb (e.g. 12d1:14ac for Huawei E182E, 12d1:1c05 for E173s)
USB_ID="12d1:1001"

# SG_DEVICE -- the device that /dev/cdrom points to when in removable storage mode
SG_DEVICE="/dev/sr0"

# SG_SWITCH_COMMAND -- some sg_raw magic, which I found burried in the usb_switchmode Message
SG_SWITCH_COMMAND="11 06 20 00 00 01 00"

# CONNECTION_INTERFACE -- name of interface we want to bring up
CONNECTION_INTERFACE="ppp0"

# USB_SWITCH_TIME -- time to wait for the switch to happen and for udev to setup the ttyUSB* (seconds)
USB_SWITCH_TIME=10
```

The important thing here is the `USB_ID` and `SG_DEVICE`.

Getting the `autoconnect`-service to autostart and bring up the ppp0 interface on boot seems a bit wonkey. Start by adding the following to `/etc/rc.local`
```
#Start autoconnect service on boot
service autoconnect start
```

`Wvdial` will complain about problems with `pap-secrets` and `chap-secrets` when connecting. Fixing it requires moving these files to `/tmp` and symlinking back.

Create the symlinks
```
ln -s /tmp/ppp-secrets/pap-secrets /etc/ppp/pap-secrets
ln -s /tmp/ppp-secrets/chap-secrets /etc/ppp/chap-secrets
```

Add to `/etc/rc.local`
```
#Something with ppp and secrets..
mkdir -p /tmp/ppp-secrets

cp /etc/ppp/original/pap-secrets /tmp/ppp-secrets
cp /etc/ppp/original/chap-secrets /tmp/ppp-secrets
```

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

To actually get an internet connection from the 3G modem when connected to the Pi via WiFi a connection between the two interfaces wlan0 and ppp0 needs to me established. This is done with iptables:

```
sudo iptables -t nat -A POSTROUTING -o ppp0 -j MASQUERADE
sudo iptables -A FORWARD -i ppp0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan0 -o ppp0 -j ACCEPT
```

To make this happen on reboot do
```
sudo sh -c "iptables-save > /etc/iptables/rules.v4"
```

## vnStat
*Not needed: https://serverfault.com/questions/533513/how-to-get-tx-rx-bytes-without-ifconfig*

We use [vnStat](https://humdi.net/vnstat/) to monitor network usage on the pi.
Install it
```
sudo apt install vnstat
```

Make sure `vnStat` is stopped as some extra configuration is needed to make it work properly with this setup:
```
sudo service vnstat stop
```

`vnStat` stores database-files for each network interface in `/var/lib/vnstat`. This isn't going to work with the read-only Pi, as it won't be able to write to these files so they have to be moved to `/tmp/vnstat` and symlinked back to `/var/lib/vnstat`.

Create the initial database-files with `vnStat`
```
vnstat -i eth1 -u
vnstat -i ppp0 -u
vnstat -i wlan0 -u
```
Set the symlinks
```
ln -s /tmp/vnstat/wlan0 /var/lib/vnstat/eth1
ln -s /tmp/vnstat/.wlan0 /var/lib/vnstat/.eth1

ln -s /tmp/vnstat/ppp0 /var/lib/vnstat/ppp0
ln -s /tmp/vnstat/.ppp0 /var/lib/vnstat/.ppp0

ln -s /tmp/vnstat/wlan0 /var/lib/vnstat/wlan0
ln -s /tmp/vnstat/.wlan0 /var/lib/vnstat/.wlan0
```

Move the files to `/var/lib/vnstat/original/` for safe keeping. The database-files needs to be moved from the `original`-directory to `/tmp` and given the right permissions on boot. Add to `/etc/rc.local`:
```
#Make vnStat work
mkdir -p /tmp/vnstat

cp /var/lib/vnstat/original/eth1 /tmp/vnstat
cp /var/lib/vnstat/original/.eth1 /tmp/vnstat

cp /var/lib/vnstat/original/ppp0 /tmp/vnstat
cp /var/lib/vnstat/original/.ppp0 /tmp/vnstat

cp /var/lib/vnstat/original/wlan0 /tmp/vnstat
cp /var/lib/vnstat/original/.wlan0 /tmp/vnstat

chown -R vnstat:vnstat /tmp/vnstat
```

Make sure permissions are right for `vnStat`
```
chown -R vnstat:vnstat /tmp/vnstat
chown -R vnstat:vnstat /var/lib/vnstat
```

Start `vnStat` again to confirm that everything works as expected
```
sudo service vnstat start
```

## Read-only SD card
Randomly killing the power (as you probably would with a headless Pi) is bad for the SD card and can lead to corruption of the file system. To avid this the pi can be setup to run in read-only mode.

Enable fastboot, disable swap and turn on read-only by editing `cmdlinex.txt`
```
sudo nano /boot/cmdline.txt
```

Add to the end of the line
```
fastboot noswap ro
```

Move `spool` (whatever that means)
```
rm -rf  /var/spool
ln -s /tmp /var/spool
```

Edit `fstab`
```
sudo nano /etc/fstab
```

Add `ro` to the root partition `/` so that i looks like this (name of the partition might vary)
```
PARTUUID=b91f7100-02  /               ext4    defaults,noatime,ro  0       1
```

Additionally add the following to the bottom of the file
```
tmpfs	/var/log	tmpfs   nodev,nosuid	0	0
tmpfs	/var/tmp	tmpfs	nodev,nosuid	0	0
tmpfs   /tmp        tmpfs   nodev,nosuid    0   0
```

Symlink `/etc/resolv.conf`
```
sudo rm /etc/resolv.conf
sudo ln -s /etc/resolvconf/run/resolv.conf /etc/resolv.conf
```

Move `dnsmasq.leases` to `/tmp`
```
touch /tmp/dnsmasq.leases
rm /var/lib/misc/dnsmasq.leases
ln -s /tmp/dnsmasq.leases /var/lib/misc/dnsmasq.leases
```

Installation of `resolvconf` is also required
```
apt install resolvconf
```

Place the following at the end of `/etc/bash.bashrc` for an easy way to switch back and forth between `RO` and `RW`
```
# set variable identifying the filesystem you work in (used in the prompt below)
fs_mode=$(mount | sed -n -e "s/^.* on \/ .*(\(r[w|o]\).*/\1/p")
# alias ro/rw 
alias ro='mount -o remount,ro / ; fs_mode=$(mount | sed -n -e "s/^.* on \/ .*(\(r[w|o]\).*/\1/p")'
alias rw='mount -o remount,rw / ; fs_mode=$(mount | sed -n -e "s/^.* on \/ .*(\(r[w|o]\).*/\1/p")'
# setup fancy prompt
export PS1='\[\033[01;32m\]\u@\h${fs_mode:+($fs_mode)}\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
# aliases for mounting boot volume
alias roboot='mount -o remount,ro /boot'
alias rwboot='mount -o remount,rw /boot'
```

Enable `Watchdog`
```
# enter RW mode
sudo -i
rw

# enable watchdog
modprobe bcm2708_wdog; apt-get install watchdog

# add bcm2708_wdog to /etc/modules to load it at boot time
$ nano /etc/modules
# /etc/modules: kernel modules to load at boot time.
#
# This file contains the names of kernel modules that should be loaded
# at boot time, one per line. Lines beginning with "#" are ignored.
bcm2708_wdog

# edit watchdog config /etc/watchdog.conf and enable (uncomment) following lines:

watchdog-device = /dev/watchdog
max-load-1

# start watchdog at system start and start right away
insserv watchdog; /etc/init.d/watchdog start

# Edit /lib/systemd/system/watchdog.service and add:
[Install]
WantedBy=multi-user.target

# now it should be enabled properly
systemctl enable watchdog

# setup automatic reboot after kernel panic in /etc/sysctl.conf (add to the end)
kernel.panic = 10

# finish and reboot
ro
reboot
```

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

Disbaled Act. LED
```
sudo nano /boot/config.txt
```

Add the following lines
```
# Disable the ACT LED on the Pi Zero.
dtparam=act_led_trigger=none
dtparam=act_led_activelow=on
```

## Resources
* https://raspberrypi.org/forums/viewtopic.php?f=38&t=50543
* https://raspberrypi.org/documentation/configuration/wireless/access-point.md
* https://learn.adafruit.com/setting-up-a-raspberry-pi-as-a-wifi-access-point/install-software
* https://flyingcarsandstuff.com/2014/11/reliable-3g-connections-with-huawei-e182ee173s-on-raspberry-pi/
* https://petr.io/en/blog/2015/11/09/read-only-raspberry-pi-with-jessie/
* https://jeffgeerling.com/blogs/jeff-geerling/raspberry-pi-zero-conserve-energy
* https://humdi.net/vnstat/
