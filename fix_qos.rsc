/ip firewall mangle
remove [ find ]

################################################################################
##  P1: TCP 3-way-handshake setup.                                            ##
################################################################################
add action=mark-packet chain=forward comment="Packet Mark: TCP SYN" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-123 \
    protocol=tcp tcp-flags=syn
add action=mark-packet chain=forward comment="Packet Mark: TCP ACK" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-64 \
    protocol=tcp tcp-flags=ack
add action=mark-packet chain=output comment="Packet Mark: TCP SYN" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-123 \
    protocol=tcp tcp-flags=syn
add action=mark-packet chain=output comment="Packet Mark: TCP ACK" \
    new-packet-mark=tcp_syn_ack out-interface=[ /interface get [ find \
    default-name=ether1 ] value-name=name ] passthrough=no packet-size=0-64 \
    protocol=tcp tcp-flags=ack
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
add action=mark-connection chain=forward comment="Classify: Google Duo calls" \
    connection-state=new dst-port=16600-18000 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=forward comment="Classify: Zoom calls" \
    dst-address-list=zoom connection-state=new new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Skype calls" \
    connection-state=new dst-port=50000-60000 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp 
add action=mark-connection chain=forward comment="Classify: Skype calls" \
    connection-state=new dst-port=3478-3481 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=5223 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=3478–3497 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp 
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=16384-16387 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
add action=mark-connection chain=forward comment="Classify: Facetime calls" \
    connection-state=new dst-port=16393-16402 new-connection-mark=video_call \
    out-interface=[ /interface get [ find default-name=ether1 ] \
    value-name=name ] passthrough=yes protocol=udp
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

################################################################################
##  Remove all connection tracking entries so classifiers start immediately.  ##
################################################################################
/ip firewall connection remove numbers=[ find ]
;
