Networking
=========

Everything to do with networking

* Static IP
* Dnsmasq
* Hostapd
* DHCP Release Hack

TODO (maybe, if i can be bothered):

* Loop through devices with static IPs

Role Variables
--------------

| Name                         | Example                                        | Description |
| ---------------------------- |----------------------------------------------- | ----------- |
| networking_interface         | _wlan0_                                        | Network interface to use
| static_ip_cidr_addr          | _10.0.0.1/24_                                  | IP Range
| dnsmasq_with_dns             | _true_                                         | Provide clients with DNS or not
| dnsmasq_ip_range_start       | _10.0.0.20_                                    | DHCP IP range start
| dnsmasq_ip_range_end         | _10.0.0.20_                                    | DHCP IP range end
| dnsmasq_subnet_mask          | _255.255.255.0_                                | Subnet mask
| dnsmasq_lease_time           | _1h_                                           | DHCP lease time
| dnsmasq_dns1                 | _1.1.1.1_                                      | Primary DNS server
| dnsmasq_dns2                 | _8.8.8.8_                                      | Secondary DNS server
| dnsmasq_static_client**1**   | _54:60:09:FC:47:A2,10.0.0.2_                   | Clients with static IPs (multiple entries for multiple clients) Format: **(MAC,IP)**
| dnsmasq_static_client**2**   | _F0:98:9D:D5:BC:AA,10.0.0.10_                  | Clients with static IPs (multiple entries for multiple clients) Format: **(MAC,IP)**
| hostapd_iface_driver         | _nl80211_                                      | WiFi driver
| hostapd_wifi_channel         | _11_                                           | WiFi channel (0 for auto)
| hostapd_wifi_country         | _DK_                                           | WiFi country (ISO 3166)
| hostapd_wifi_ssid            | _MEGABoominator_                               | WiFi SSID
| hostapd_wifi_password        | _ThunderDucks_                                 | WiFI password