Prepare OS
=========

Initial changes to the Raspbian operation system:

* Change locale
* WiFI Setup (Country, SSID and Password)
* New hostname
* Disbale LEDs

TODO (maybe, if i can be bothered):

* Set keyboard layout
* Expand filesystem

Role Variables
--------------

| Name              | Example         | Description |
| ----------------- |---------------- | ----------- |
| locale_locale     | _en_IE.utf8_    | https://en.m.wikipedia.org/wiki/Locale_(computer_software)
| wifi_country      | _DK_            | Country code for the WiFi settings. https://en.m.wikipedia.org/wiki/ISO_3166-1
| wifi_ssid         | _ThunderDucks_  | WiFi SSID
| wifi_psk          | _p4$$w0rd_      | WiFi Password
| hostname_hostname | _MEGAPi_        | Set the hostname for the Pi