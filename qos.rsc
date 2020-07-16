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
    comment="Classify: Generic Voice Traffic, DSCP EF 46" connection-state=new \
    dscp=46 new-connection-mark=voice_call out-interface=[ /interface get \
    [ find default-name=ether1 ] value-name=name ] passthrough=yes
add action=mark-packet chain=forward comment="Packet Mark: Voice call" \
    connection-mark=voice_call new-packet-mark=voice_call passthrough=no
################################################################################
##  P4: Video calls.                                                          ##
################################################################################
add action=mark-connection chain=forward \
    comment="Classify: Google Hangouts/Meet Audio/Video, DSCP 40" \
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
    connection-state=new dst-port=25 new-connection-mark=bulk \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-connection chain=forward comment="Classify: FTP" \
    connection-state=new connection-type=ftp new-connection-mark=bulk \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=tcp
add action=mark-packet chain=forward comment="Mark Packet: bulk" \
    connection-mark=bulk new-packet-mark=bulk passthrough=no
################################################################################
##  P7: Default flows. n.b., this P7 is intentionally entered after P8.       ##
################################################################################
add action=mark-packet chain=forward comment="Packet Mark: Default" \
    new-packet-mark=default passthrough=no
