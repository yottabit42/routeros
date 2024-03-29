# RouterOS Configurations

## dual_wan_failover.rsc
### Dual-WAN failover using RouterOS v7.1.1.

Useful for using a phone hotspot, or another slower backup Internet provider
for failover in case the primary fails. Checks every one second, with automatic
restoration.
* Uses WAN1 for primary default gateway, and checks Google Honest DNS 8.8.8.8
  for reachability.
* Uses WAN2 for secondary (failover) default gateway, and checks Google Honest
  DNS 8.8.4.4 for reachability.
 
## audience_rb1_tweaks.rsc
### Tweaks to Audience base configuration running as router + AP.
* Sets router password
* Sets hostname
* Sets timezone
* Add extra user
  * Typically used for remote access via SSH pubkey
  * Installation of pubkey disables password logins for that user by default
* Restrict the admin user to login from the default LAN only, to protect against
  weak passwords and brute-force attempts to login from the WAN
* Enable NTP client set to time1.google.com and time2.google.com
* Create a daily scheduled event edits the NTP client configuration by resolving
  time1.google.com and time2.google.com in case of IP address changes
* Enables interface statistic graphing
* Enables resource statistic graphing
* Installs the BackupAndUpdate script and daily scheduled event
  * Checks for new RouterOS and RouterBOOT versions daily at 0300
  * Performs before-upgrade backup
  * Upgrades
  * Performs after-upgrade backup
  * Can be configured to mail the backups to a user (not enabled by default)
* Tweaks the CAPsMAN configuration for extra performance
  * Sets the 2 GHz channels to 1, 6, and 11 only (2412, 2437, and 2462 MHz)
  * Sets the 5 GHz to n+ac mode only
  * Sets the channel width to 80 MHz
  * Sets the distance to indoors
  * Disables keepalive frames
  * Sets security to wpa2 only
  * Disables pmkid for security
  * Sets the group key timeout to 1h
* Tweaks the wlan3 default interfaces with tuned parameters for extra
  performance
  * Enables adaptive noise immunity mode
  * Sets the interface to 802.11ac mode only
  * Sets the channel width to 80 MHz
  * Sets the distance to indoors
  * Disables keepalive frames
  * Enables WMM
  * Sets security to wpa2 only
  * Disables pmkid for security
  * Sets the frequency to auto
* Enables MikroTik DDNS
* Sets DHCP lease time to 1d
* Sets the DNS servers preference
* Sets the SSH port to 16774
* Allows SSH from the WAN interface
* Enables a Queue Tree configuration for QoS
  * See **qos.rsc** section for more information

## audience_rbX_tweaks.rsc
### Tweaks to Audience base configuration running as extension/repeater.
* Sets router password
* Sets hostname
* Sets timezone
* Add extra user
  * Typically used for remote access via SSH pubkey
  * Installation of pubkey disables password logins for that user by default
* Restrict the admin user to login from the default LAN only, to protect against
  weak passwords and brute-force attempts to login from the WAN
* Enable NTP client set to time1.google.com and time2.google.com
* Create a daily scheduled event edits the NTP client configuration by resolving
  time1.google.com and time2.google.com in case of IP address changes
* Enables interface statistic graphing
* Enables resource statistic graphing
* Installs the BackupAndUpdate script and daily scheduled event
  * Checks for new RouterOS and RouterBOOT versions daily at 0300
  * Performs before-upgrade backup
  * Upgrades
  * Performs after-upgrade backup
  * Can be configured to mail the backups to a user (not enabled by default)
* Tweaks the wlan4 and wlan3 default interfaces with tuned parameters for extra
  performance

## fail2ban.rsc
### Basic emulation of the fail2ban application directly in Router OS.

**Important:** These rules must be placed higher than a matching drop rule, or
it will have no effect.

Block SSH attempts to the router by detecting four attempts within three
minutes. Unlike fail2ban, SSH log files are not analyzed, and a simpler approach
is used.

If the same source IP address attempts to make four new connections to the SSH
port (TCP/22) within three minutes, we assume it is being denied login, and it
continues to guess common usernames and passwords. At that point the source IP
address is added to an SSH blacklist for one day.

Attempts by the source IP address to access other services is not blocked, but
the script is easily modified to block all access, if desired. Remove the
`protocol` and `dst-port` definitions from the first rule, and all services will
be blocked from that source address to the router.

If you desire to block SSH attempts to devices behind the router, change
`chain=input` to `chain=forward` for all rules, and optionally adjust other
matching criteria as needed.

You can also adapt the ruleset to  support other services such as FTP, etc., by
adjusting the matching criteria. Keep in mind whether you need `chain=input`
(the router itself) or `chain=forward` (devices behind the router), and adjust
accordingly.

## installBackupAndUpdate.rsc
### Script to install an automated Backup & Update script & scheduler.

Originally forked from https://github.com/beeyev at version 20.04.17 (2020-04-17).
Customized to be more friendly to local backups by:
1. Not requiring an email address and sending configuration
1. Checking free space before backup, and clearing old backups if necessary
1. Preserving local backup files

## qos.rsc
### 2-Step QoS using using eight priorities and a preconfigured set of classifiers.

**Important:** The script assumes you are using the default `ether1` WAN/Internet
interface. If you are using something else, change this value everywhere in the
script.

**Important:** The script automatically disables the fasttrack rule from the
stock configuration. If you have created other _action=fasttrack-connection_
rules, you will need to disable them manually in IP -> Firewall -> Filter, or
Queue Tree cannot work properly on outbound traffic classified for 
prioritization. You can disable these rules by clicking the "D" button in Webfig
or Winbox, rather than deleting with the "-" button.

**Important:** You must perform upload speed tests to your ISP's **own** servers
to determine your exact generally achievable rate. Set the `max-limit=` to
90-95% of your generally achievable rate, or QoS will not function! You can
specify an exact bitrate, or use the "k" and "M" suffixes; decimals are not
allowed (i.e., use 8400k instead of 8.4M). After full configuration of the QoS
rules, test the upload speed again. While testing, watch the Queue Tree counters
to ensure you see Queued bytes. If you do not see some queued bytes, the
`max-limit=` is set too high.
* Do not test to common speed test services such as speedtest.net, Google,
  Netflix (fast.com), speedof.me, etc., unless your ISP does not provide a
  direct speed test service.
* You may need to contact your ISP to find out which address to use for
  conducting a speed test, and you should try to use a wired connection
  directly to your router or modem, if at all possible. The goal is to measure
  your generally available upload speed to your ISP, not through the ISP to the
  Internet.

**Important:** The order in which the Firewall IP Mangle rules are entered is
important for maximum efficiency. And specifically, the classifier for priority
#8 (Bulk) is entered before the classifier for priority #7 (Default), as the
rules are matched in order and priority #7 is being used as the default for no
other matches. If you add new classifiers, be sure they are moved into the same
area as the other classifers for the same class, and always before the
`action=mark-packet` rule.

#### General discussion

The queue tree consists of a parent queue for managing the upstream rate of your
Internet connection. (You generally cannot QoS the downstream connections as you
do not have any control of the priority in which your ISP shuffles packets
destined for your network. There is an exception when you wish to limit
per-connection transfer rates, PCQ, but that is out of scope for this ruleset.)

Under the parent queue are eight child queues, mapping to each of the eight
priorities defined.

The IP Firewall Mangle commands use a 2-step approach to maximize the efficiency
of your CPU--especially important for single-core MIPS CPUs and high-speed
Internet connections.

Rather than deep-inspecting every packet, we take a more efficient approach:
1. Deep-inspect, and mark as priority 1, every TCP SYN packet <= 123 bytes,
every TCP SYN-ACK packet <= 123 bytes, and every TCP ACK packet.
   * This allows the TCP 3-way handshake (setup) protocol to finish as fast as
     possible, minimizing latency of new connections, and maximizing download
     speed.
1. Deep-inspect only the first packet of new connections, that is, connections
   that are not already tracked in the Connection Tracking table.
   * Note: Connection Tracking must be enabled for the 2-step method to work.
     It is on by default, and must be used for NAT to function, so it is
     typically enabled on nearly all home and small-office networks.
1. Classify the new connection based on a variety of patterns found in the
   packets, including port numbers, DSCP bits, MAC addresses, etc.
1. Mark the connection based on the classification rule match.
1. Mark the packets according to the connection marking in the Connection
   Tracking table, which is much more efficient than deep-inspecting every
   packet.
1. The Queue Tree configuration prioritizes the outbound packet based on its
   packet marking value.
   
The "2-step QoS" approach is generally defined as such:
1. Mark the connection by evaluting only the first packet
1. Mark all packets of the connection by checking the value of the Connection
   marking

#### Defined Queues (1-8, from highest-to-lowest priority)

The eight queues are arranged as follows, in order of highest priority to
lowest:
1. TCP 3-way handshake and TCP ACKs. This allows the setup of new TCP
   connections to happen quickly, which improves responsiveness of applications
   and allows TCP window-scaling to finish quicker for faster "speed-up" of
   downloads. The packet size match allows up to 123 bytes to incorporate the
   recent extensions to the TCP handshake for scaling and timestamps.
1. Domain Name Service (DNS) and Network Time Protocol (NTP). This allows both
   forwarded (`chain=forward`) and router-initiated (`chain=output`) DNS and NTP
   requests to be prioritized over almost all other traffic. Faster DNS response
   generally lends to everything else being faster, and faster NTP response
   allows for more precise time synchronization.
1. Voice calls. Any service on the network setting the DSCP bits to EF 46 will
   be considered as voice calls. You should also add any mobile carrier coverage
   devices, or VoIP telephones, by MAC address or IP address to a classifier
   rule, as they often use IPSec tunnels to secure the communication from the
   coverage device back to the mobile operator.
   * If you use IP address, ensure the IP addresses are configured statically on
     the device, or configured with a static rule in the DHCP server.
1. Video calls. Any service on the network setting the DSCP bits to 40 will be
   considered as voice calls. In addition Google Meets and Google Hangouts are
   classified. You should also add any dedicated voice-calling devices by MAC
   address or IP address to a classifier rule, as setting DSCP bits on
   non-enterprise networks is rarely done.
   * TODO: add classifers for Zoom, Duo, Skype, and Facetime.
   * If you use IP address, ensure the IP addresses are configured statically on
     the device, or configured with a static rule in the DHCP server.
1. Interactive flows. Secure Shell (SSH) and telnet are included here. Other
   common devices that should be placed into this queue, by MAC address or IP
   address, are Stadia controllers so that latency-sensitive games are not
   impacted negatively by congestion or competition.
   * There no simple method to determine if an SSH connection is being used as
     an interactive session v. secure file transfer (SFTP), so be aware that
     file transfers may be unintentionally set to a fairly high priority. If
     this is a problem, you can disable or delete the SSH classifier, or set the
     SSH classifier to use the _bulk_ queue.
   * If you use a work computer that uses VPN to reach the corporate network,
     adding a classifier for its MAC address or IP address to this queue is
     generally a good compromise.
   * If you use IP address, ensure the IP addresses are configured statically
     on the device, or configured with a static rule in the DHCP server.
 1. HTTP/HTTPS flows. General web requests, and many other applications, use
    the HTTP or HTTPS/SSL/TLS protocols.
 1. Default flows. This is a catch-all for all unclassified traffic. Any
    traffic that does not match one of the classifiers is put into this queue.
 1. Bulk flows. This includes Simple Mail Transfer Protocol (SMTP), and File
    Transfer Protocol (FTP). This is purposefully created to use the lowest
    priority for bulk transfers such as file servers, backups, etc. By default
    no services except SMTP and FTP will match this queue, and those are
    uncommonly used now. You will need to create classifiers to match the
    services or devices you wish to use this queue.
