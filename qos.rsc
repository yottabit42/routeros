# jul/15/2020 12:37:42 by RouterOS 6.47.1

/queue tree
################################################################################
##  You must perform upload speed tests to your ISP's own servers to          ##
##  determine your exact generally achievable rate. Set the max-limit= to     ##
##  90-95% of your generally achievable rate, or QoS will not function!       ##
##  You can specify an exact bitrate, or use the "k" and "M" abbreviations,   ##
##  but decimals are not allowed (i.e., use 8400k instead of 8.4M). After     ##
##  full configuration of the QoS rules, test the upload speed again. While   ##
##  testing, watch the Queue Tree counters to ensure you see Queued bytes.    ##
##  If you do not, the max-limit= is set too high.                            ##
################################################################################
##  If you do not use default port ether1 for your WAN/Internet interface,    ##
##  change the value of ether1 everywhere in this script to the correct port. ##
################################################################################
add max-limit=000000k name=iNetEgress \
    parent=[ /interface get [ find default-name=ether1 ] value-name=name ] \
    queue=wireless-default
add name=1_TCP_SYN_ACK packet-mark=tcp_syn_ack parent=iNetEgress priority=1 \
    queue=wireless-default
add name=2_DNS_NTP packet-mark=dns_ntp parent=iNetEgress priority=2 \
    queue=wireless-default
add name=3_Voice_Calling packet-mark=voice_call parent=iNetEgress priority=3 \
    queue=wireless-default
add name=4_Video_Calling packet-mark=video_call parent=iNetEgress priority=4 \
    queue=wireless-default
add name=5_Interactive packet-mark=interactive parent=iNetEgress priority=5 \
    queue=wireless-default
add name=6_HTTP_HTTPS packet-mark=http_https parent=iNetEgress priority=6 \
    queue=wireless-default
add name=7_Default packet-mark=default parent=iNetEgress priority=7 \
    queue=wireless-default
add name=8_Bulk packet-mark=bulk parent=iNetEgress priority=8 \
    queue=wireless-default

################################################################################
##  Address lists for Zoom. Reference:                                        ##
##  https://support.zoom.us/hc/en-us/articles/201362683-Network-firewall-or-proxy-server-settings-for-Zoom
################################################################################
/ip firewall address-list
    add list=zoom address=3.7.35.0/25
    add list=zoom address=3.21.137.128/25
    add list=zoom address=3.22.11.0/24
    add list=zoom address=3.23.93.0/24
    add list=zoom address=3.25.41.128/25
    add list=zoom address=3.25.42.0/25
    add list=zoom address=3.25.49.0/24
    add list=zoom address=3.80.20.128/25
    add list=zoom address=3.96.19.0/24
    add list=zoom address=3.101.32.128/25
    add list=zoom address=3.101.52.0/25
    add list=zoom address=3.104.34.128/25
    add list=zoom address=3.120.121.0/25
    add list=zoom address=3.127.194.128/25
    add list=zoom address=3.208.72.0/25
    add list=zoom address=3.211.241.0/25
    add list=zoom address=3.235.69.0/25
    add list=zoom address=3.235.82.0/23
    add list=zoom address=3.235.71.128/25
    add list=zoom address=3.235.72.128/25
    add list=zoom address=3.235.73.0/25
    add list=zoom address=3.235.96.0/23
    add list=zoom address=4.34.125.128/25
    add list=zoom address=4.35.64.128/25
    add list=zoom address=8.5.128.0/23
    add list=zoom address=13.52.6.128/25
    add list=zoom address=13.52.146.0/25
    add list=zoom address=13.114.106.166/32
    add list=zoom address=18.157.88.0/24
    add list=zoom address=18.205.93.128/25
    add list=zoom address=50.239.202.0/23
    add list=zoom address=50.239.204.0/24
    add list=zoom address=52.61.100.128/25
    add list=zoom address=52.81.151.128/25
    add list=zoom address=52.81.215.0/24
    add list=zoom address=52.197.97.21/32
    add list=zoom address=52.202.62.192/26
    add list=zoom address=52.215.168.0/25
    add list=zoom address=64.69.74.0/24
    add list=zoom address=64.125.62.0/24
    add list=zoom address=64.211.144.0/24
    add list=zoom address=65.39.152.0/24
    add list=zoom address=69.174.57.0/24
    add list=zoom address=69.174.108.0/22
    add list=zoom address=99.79.20.0/25
    add list=zoom address=103.122.166.0/23
    add list=zoom address=109.94.160.0/22
    add list=zoom address=109.244.18.0/25
    add list=zoom address=109.244.19.0/24
    add list=zoom address=111.33.181.0/25
    add list=zoom address=115.110.154.192/26
    add list=zoom address=115.114.56.192/26
    add list=zoom address=115.114.115.0/26
    add list=zoom address=115.114.131.0/26
    add list=zoom address=120.29.148.0/24
    add list=zoom address=140.238.128.0/24
    add list=zoom address=147.124.96.0/19
    add list=zoom address=149.137.0.0/17
    add list=zoom address=152.67.20.0/24
    add list=zoom address=152.67.118.0/24
    add list=zoom address=152.67.180.0/24
    add list=zoom address=158.101.64.0/24
    add list=zoom address=160.1.56.128/25
    add list=zoom address=161.189.199.0/25
    add list=zoom address=161.199.136.0/22
    add list=zoom address=162.12.232.0/22
    add list=zoom address=162.255.36.0/22
    add list=zoom address=165.254.88.0/23
    add list=zoom address=168.138.16.0/24
    add list=zoom address=168.138.48.0/24
    add list=zoom address=168.138.72.0/24
    add list=zoom address=168.138.244.0/24
    add list=zoom address=173.231.80.0/20
    add list=zoom address=192.204.12.0/22
    add list=zoom address=193.122.32.0/22
    add list=zoom address=193.123.0.0/19
    add list=zoom address=193.123.40.0/22
    add list=zoom address=193.123.128.0/19
    add list=zoom address=198.251.128.0/17
    add list=zoom address=198.251.192.0/22
    add list=zoom address=202.177.207.128/27
    add list=zoom address=202.177.213.96/27
    add list=zoom address=204.80.104.0/21
    add list=zoom address=204.141.28.0/22
    add list=zoom address=207.226.132.0/24
    add list=zoom address=209.9.211.0/24
    add list=zoom address=209.9.215.0/24
    add list=zoom address=210.57.55.0/24
    add list=zoom address=213.19.144.0/24
    add list=zoom address=213.19.153.0/24
    add list=zoom address=213.244.140.0/24
    add list=zoom address=221.122.88.64/27
    add list=zoom address=221.122.88.128/25
    add list=zoom address=221.122.89.128/25
    add list=zoom address=221.123.139.192/27
    add list=zoom address=2620:123:2000::/40

################################################################################
##  Fasttrack must be disabled for Queue Trees to function.                   ##
##  Note: only the stock configuration rule is matched and disabled; if you   ##
##  have created other fasttrack rules, you will need to disable them         ##
##  manually if they would match outbound traffic for prioritization.         ##
################################################################################
/ip firewall filter
disable [ find action=fasttrack-connection chain=forward \
        connection-state=established,related ]

/ip firewall mangle
################################################################################
##  P1: TCP 3-way-handshake setup.                                            ##
################################################################################
add action=mark-packet chain=forward comment="Packet Mark: TCP SYN" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-123 \
    protocol=tcp tcp-flags=syn
add action=mark-packet chain=forward comment="Packet Mark: TCP SYN-ACK" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-123 \
    protocol=tcp tcp-flags=ack,syn
add action=mark-packet chain=forward comment="Packet Mark: TCP ACK" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no protocol=tcp \
    tcp-flags=ack
add action=mark-packet chain=output comment="Packet Mark: TCP SYN" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-123 \
    protocol=tcp tcp-flags=syn
add action=mark-packet chain=output comment="Packet Mark: TCP SYN-ACK" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-123 \
    protocol=tcp tcp-flags=ack,syn
add action=mark-packet chain=output comment="Packet Mark: TCP ACK" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no protocol=tcp \
    tcp-flags=ack
################################################################################
##  P2: Domain Name Service and Network Time Protocol.                        ##
################################################################################
add action=mark-connection chain=output comment="Classify: NTP" \
    connection-state=new dst-port=123 new-connection-mark=dns_ntp \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=output comment="Classify: DNS, UDP" \
    connection-state=new dst-port=53 new-connection-mark=dns_ntp \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=output comment="Classify: DNS, TCP" \
    connection-state=new dst-port=53 new-connection-mark=dns_ntp \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-packet chain=output comment="Packet Mark: DNS" \
    connection-mark=dns_ntp new-packet-mark=dns_ntp passthrough=no
add action=mark-connection chain=forward comment="Classify: NTP" \
    connection-state=new dst-port=123 new-connection-mark=dns_ntp \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=forward comment="Classify: DNS, UDP" \
    connection-state=new dst-port=53 new-connection-mark=dns_ntp \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=forward comment="Classify: DNS, TCP" \
    connection-state=new dst-port=53 new-connection-mark=dns_ntp \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-packet chain=forward comment="Packet Mark: DNS" \
    connection-mark=dns_ntp new-packet-mark=dns_ntp passthrough=no
################################################################################
##  P3: Voice calls.                                                          ##
################################################################################
# Example for classifying a femtocell coverage device by MAC address.
#add action=mark-connection chain=forward \
#    comment="Classify: T-Mobile femtocell" connection-state=new \
#    new-connection-mark=voice_call out-interface=[ /interface get [ find \
#    default-name=ether1 ] value-name=name ] passthrough=yes \
#    src-mac-address=B4:EE:B4:A6:23:0E
add action=mark-connection chain=forward \
    comment="Classify: Generic Voice Traffic, DSCP 46" connection-state=new \
    dscp=46 new-connection-mark=voice_call out-interface=[ /interface get \
    [ find default-name=ether1 ] value-name=name ] passthrough=yes
add action=mark-connection chain=forward \
    comment="Classify: Generic Voice Traffic, DSCP 56" connection-state=new \
    dscp=56 new-connection-mark=voice_call out-interface=[ /interface get \
    [ find default-name=ether1 ] value-name=name ] passthrough=yes
add action=mark-packet chain=forward comment="Packet Mark: Voice call" \
    connection-mark=voice_call new-packet-mark=voice_call passthrough=no
################################################################################
##  P4: Video calls.                                                          ##
################################################################################
add action=mark-connection chain=forward \
    comment="Classify: Generic Video Traffic, DSCP 40" \
    connection-state=new dscp=40 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes
add action=mark-connection chain=forward \
    comment="Classify: Google Hangouts/Meet, UDP DstPort" connection-state=new \
    dst-port=19302-19309 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=forward \
    comment="Classify: Google Hangouts/Meet, TCP DstPort" connection-state=new \
    dst-port=19305-19309 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
# TODO: Classifiers for Zoom, Skype, Duo, Facetime.
add action=mark-connection chain=forward comment="Classify: Google Duo calls" \
    connection-state=new dst-port=16600-18000 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    protocol=udp value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Zoom calls" \
    dst-address-list=zoom connection-state=new new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Skype calls" \
    connection-state=new dst-port=50000-60000 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    protocol=udp value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Skype calls" \
    connection-state=new dst-port=3478-3481 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    protocol=udp value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=5223 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=3478–3497 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    protocol=udp value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=16384-16387 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    protocol=udp value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=16393-16402 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    protocol=udp value-name=name ] passthrough=yes
add action=mark-packet chain=forward comment="Packet Mark: Video call" \
    connection-mark=video_call new-packet-mark=video_call passthrough=no
################################################################################
##  P5: Interactive flows.                                                    ##
################################################################################
# Example for interactive device by MAC, such as Stadia Wi-Fi controller.
#add action=mark-connection chain=forward comment=stadia-1404 \
#    connection-state=new new-connection-mark=interactive \
#    out-interface=[ /interface get [ find default-name=ether1 ] \
#    value-name=name ] passthrough=yes src-mac-address=F0:EF:86:0C:48:77
add action=mark-connection chain=forward comment="Classify: SSH" \
    connection-state=new dst-port=22 new-connection-mark=interactive \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-connection chain=forward comment="Classify: Telnet" \
    connection-state=new dst-port=23 new-connection-mark=interactive \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-packet chain=forward comment="Packet Mark: Interactive" \
    connection-mark=interactive new-packet-mark=interactive passthrough=no
################################################################################
##  P6: HTTP/HTTPS flows.                                                     ##
################################################################################
add action=mark-connection chain=forward comment="Classify: HTTP, HTTPS" \
    connection-state=new dst-port=80,443 new-connection-mark=http_https \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ]  passthrough=yes protocol=tcp
add action=mark-packet chain=forward comment="Packet Mark: HTTP, HTTPS" \
    connection-mark=http_https new-packet-mark=http_https passthrough=no
################################################################################
##  P8: Bulk flows.                                                           ##
################################################################################
# Example for bulk-only device by MAC address.
#add action=mark-connection chain=forward comment="Classify: File server" \
#    connection-state=new new-connection-mark=bulk out-interface=[ /interface \
#    get [ find default-name=ether1 ] value-name=name ] passthrough=yes \
#    src-mac-address=F8:0F:F9:49:DB:4B
add action=mark-connection chain=forward comment="Classify: SMTP" \
    connection-state=new dst-port=25,465,2525 new-connection-mark=bulk \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-connection chain=forward comment="Classify: FTP" \
    connection-state=new connection-type=ftp new-connection-mark=bulk \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-connection chain=forward comment="Classify: FTPS" \
    connection-state=new dst-port=990 new-connection-mark=bulk \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-packet chain=forward comment="Mark Packet: bulk" \
    connection-mark=bulk new-packet-mark=bulk passthrough=no
################################################################################
##  P7: Default flows. n.b., this P7 is intentionally entered after P8.       ##
################################################################################
add action=mark-packet chain=forward comment="Packet Mark: Default" \
    new-packet-mark=default passthrough=no
