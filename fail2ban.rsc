# jul/15/2020 12:37:42 by RouterOS 6.47.1

################################################################################
##  Basic emulation of the fail2ban application directly in Router OS.        ##
################################################################################
##  These rules must be placed higher than a matching drop rule.              ##
################################################################################
##  Block SSH attempts to router by detecting 4 attempts within 3 minutes.    ##
##  Change chain=input to chain=forward to block SSH forwarding to devices    ##
##  behind the router, instead of the router itself. Can also adapt to        ##
##  support other services such as FTP, etc.                                  ##
################################################################################

/ip firewall filter

# If IP is in address list ssh_blacklist, drop the packet.
add chain=input protocol=tcp dst-port=22 src-address-list=ssh_blacklist \
    action=drop comment="Drop SSH high-frequency attempts" disabled=no

# If IP in ssh_stage3 and state is new, add IP ssh_blacklist for 1 day.
add chain=input protocol=tcp dst-port=22 connection-state=new \
    src-address-list=ssh_stage3 action=add-src-to-address-list \
    address-list=ssh_blacklist address-list-timeout=1d \
    comment="Ban IP from SSH for 1 day" disabled=no

# If IP in ssh_stage2 and state is new, add IP to address list ssh_stage3.
add chain=input protocol=tcp dst-port=22 connection-state=new \
    src-address-list=ssh_stage2 action=add-src-to-address-list \
    address-list=ssh_stage3 address-list-timeout=1m \
    comment="Detect 3rd SSH attempt within 2 minutes" disabled=no

# If IP in ssh_stage1 and state is new, add IP to address list ssh_stage2.
add chain=input protocol=tcp dst-port=22 connection-state=new \
    src-address-list=ssh_stage1 action=add-src-to-address-list \
    address-list=ssh_stage2 address-list-timeout=1m \
    comment="Detect 2nd SSH attempt within 1 minute" disabled=no

# Add IP to address list ssh_stage1.
add chain=input protocol=tcp dst-port=22 connection-state=new \
    action=add-src-to-address-list address-list=ssh_stage1 \
    address-list-timeout=1m comment="Detect 1st SSH attempt" disabled=no
