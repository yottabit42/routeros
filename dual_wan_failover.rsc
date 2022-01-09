##
# Dual-WAN failover using RouterOS v7.1.1.
# 
# WAN1 is frontier connected on ether1 and uses DHCP.
#
# WAN2 is tmus connected on wlan1 and uses DHCP. wlan1 is configured in
# station mode to a phone hotspot. Remember that if you use wlan1 as an
# independent WAN interface, remove it from the LAN bridge first.
##

# Add the NAT masquerade rules.
/ip/firewall/nat
add chain=srcnat action=masquarade out-interface=ether1
add chain=srcnat action=masquarade out-interface=wlan1

# Add the two WAN routing FIBs.
/routing
add fib name=frontier
add fib name=tmus

# Add mangle rules for marking the traffic.
/ip/firewall/mangle
add chain=output connection-state=new connection-mark=no-mark\
    action=mark-connection new-connection-mark=frontier\
    out-interface=ether1
add chain=output connection-mark=frontier action=mark-routing\
    new-routing-mark=frontier out-interface=ether1
add chain=output connection-state=new connection-mark=no-mark\
    action=mark-connection new-connection-mark=tmus\
    out-interface=wlan1
add chain=output connection-mark=tmus action=mark-routing\
    new-routing-mark=tmus out-interface=wlan1

# Add the hosts that will be used for connectivity checking. This will
# use Google Honest DNS 8.8.8.8 for the primary WAN and 8.8.4.4 for the
# failover WAN. The gateway addresses will be automatically updated by
# the DHCP Client script installed as the last step.
/ip/route
add dst-address=8.8.8.8/32 gateway=47.186.42.1 scope=30 target-scope=30
add dst-address=8.8.4.4/32 gateway=192.168.43.80 scope=30\
    target-scope=30

# Add the recursive default routes with the gateway checks.
/ip/route
add check-gateway=ping gateway=8.8.8.8 routing-table=frontier scope=30\
    target-scope=30
add check-gateway=ping gateway=8.8.4.4 routing-table=frontier scope=30\
    target-scope=30

# Tweak your DHCP clients to apply a high default route and update the
# recursive route gateway with the DHCP gateway upon lease.
/ip/dhcp-client
add default-route-distance=10 interface=ether1 script=\
    "/ip/route/set numbers=[find dst-address=8.8.8.8]\
    gateway=[/ip/dhcp-client/get value-name=gateway\
    [find interface=ether1]]" use-peer-dns=no use-peer-ntp=no
add default-route-distance=11 interface=wlan1 script=\
    "/ip/route/set numbers=[find dst-address=8.8.4.4]\
    gateway=[/ip/dhcp-client/get value-name=gateway\
    [find interface=wlan1]]" use-peer-dns=no use-peer-ntp=no
