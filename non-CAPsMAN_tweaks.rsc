# aug/06/2020 18:56:50 by RouterOS 6.47.1
# model = RBD25G-5HPacQD2HPnD

################################################################################
# rb1.local - non-CAPsMAN main router
################################################################################
:global passwd "qy56pe5tpDZJCs085Q8c"
:global identity "rb1.local"
# "" or "8.8.8.8,8.8.4.4", etc.
:global dns "8.8.8.8,8.8.4.4"
:global sshPort "16774"
# "America/Chicago", "America/Los_Angeles", etc.
:global timezone "America/Chicago"
:global disableYottabit "yes"
# Leave unset to skip QoS configuration; otherwise set to p20 of upload tests.
# Note: QoS has been removed from this script, pending re-implementation of a
# downloadable and installable version.
# :global uploadRate ""
################################################################################

# This password will be disabled automatically when the SSH pubkey is added, but
# we assign a strong password here just for safety in case the SSH pubkey is
# forgotten or deleted.
/user
add name="yottabit" group="full" disabled="$disableYottabit" \
    password="qy56pe5tpDZJCs085Q8c"
# SSH will be open to the Internet; only allow password login from the LAN.
set [ find name=admin ] password="$passwd" address=192.168.88.0/24

/interface wireless
set [ find band=5ghz-n/ac ] wds-mode=dynamic-mesh wds-default-bridge=bridge
set [ find band=2ghz-onlyn ] scan-list=2412,2437,2462
set [ find ] adaptive-noise-immunity=ap-and-client-mode \
    country="united states3" frequency-mode=regulatory-domain \
    keepalive-frames=disabled wireless-protocol=802.11 wmm-support=enabled

/interface wireless security-profiles
set [ find ] authentication-types=wpa2-psk group-key-update=1h disable-pmkid=yes 

/ip cloud
set ddns-enabled=yes

/ip dhcp-server
set [ find ] lease-time=1d

/ip dns set servers="$dns"

/ip service
set ssh port="$sshPort"

/ip firewall filter
add action=accept chain=input comment="Accept SSH from WAN" dst-port=16774 \
    in-interface-list=WAN protocol=tcp place-before=1

/system clock
set time-zone-name="$timezone"

/system identity
set name="$identity"

/system ntp client
set enabled=yes primary-ntp=[ :resolve time1.google.com ] \
    secondary-ntp=[ :resolve time2.google.com ]

/system scheduler
add interval=1d name=UpdateTimeServers on-event="/system ntp client\r\
    \nset enabled=yes primary-ntp=[ :resolve time1.google.com ] \\\r\
    \n    secondary-ntp=[ :resolve time2.google.com ];" policy=\
    read,write start-date=jan/01/1970 start-time=00:00:00

/tool graphing interface add

/tool graphing resource add

# Temporarily removed.
# :if ($uploadRate != "") do={

/system script environment
remove [ find name="passwd" ]
remove [ find name="identity" ]
remove [ find name="dns" ]
remove [ find name="sshPort" ]
remove [ find name="timezone" ]
remove [ find name="sshDisable" ]
remove [ find name="uploadRate" ]
remove [ find name="disableYottabit" ]

/tool fetch mode=https url="https://raw.githubusercontent.com/yottabit42/routeros/master/installBackupAndUpdate.rsc" output=file as-value
/import file-name="installBackupAndUpdate.rsc"
:delay 2
/file remove [ find name~"installBackupAndUpdate.rsc" ]

# Import the SSH pubkey.
