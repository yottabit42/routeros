# aug/06/2020 18:56:50 by RouterOS 6.47.1
# model = RBD25G-5HPacQD2HPnD

################################################################################
# rbX.local - non-CAP extension APs
# Start from a blank config (System -> Reset Configuration -> No Defaults)
################################################################################
:global passwd ""
:global identity "rb2.local"
:global wifiSSID ""
:global wifiWPA2 ""
# "America/Chicago", "America/Los_Angeles", etc.
:global timezone "America/Chicago"
################################################################################

# This password will be disabled automatically when the SSH pubkey is added, but
# we assign a strong password here just for safety in case the SSH pubkey is
# forgotten or deleted.
/user
add name="yottabit" group="full" \
    password="foobaryaz"
# SSH will be open to the Internet; only allow password login from the LAN.
set [ find name=admin ] password="$passwd" address=192.168.88.0/24

/system clock
set time-zone-name="$timezone"

/system identity
set name="$identity"

/interface bridge
add name=bridge1

/interface bridge port
add bridge=bridge1 interface=all

/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=bridge1

:delay 7

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

/tool fetch mode=https url="https://raw.githubusercontent.com/yottabit42/routeros/master/installBackupAndUpdate.rsc" output=file as-value
/import file-name="installBackupAndUpdate.rsc"
:delay 2
/file remove [ find name~"installBackupAndUpdate.rsc" ]

/interface wireless security-profiles
set [ find default=yes ] authentication-types=wpa2-psk disable-pmkid=yes \
    group-key-update=1h mode=dynamic-keys wpa2-pre-shared-key="$wifiWPA2"

/interface wireless
set [ find band=2ghz-b/g ] band=2ghz-onlyn channel-width=20/40mhz-XX \
    mode=ap-bridge scan-list=2412,2437,2462 ssid="$wifiSSID"
set [ find band=5ghz-a ] band=5ghz-n/ac channel-width=20/40/80mhz-XXXX \
    mode=wds-slave ssid="$wifiSSID" wds-default-bridge=bridge1 \
    wds-mode=dynamic-mesh
set [ find ] adaptive-noise-immunity=ap-and-client-mode country="united states3" \
    disabled=no distance=indoors frequency=auto frequency-mode=regulatory-domain \
    keepalive-frames=disabled wireless-protocol=802.11 wmm-support=enabled

/system script environment
remove [ find name="passwd" ]
remove [ find name="identity" ]
remove [ find name="wifiSSID" ]
remove [ find name="wifiWPA2" ]
remove [ find name="timezone" ]

# Import the SSH pubkey.
