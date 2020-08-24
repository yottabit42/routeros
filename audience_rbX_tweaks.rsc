# aug/06/2020 18:56:50 by RouterOS 6.47.1
# model = RBD25G-5HPacQD2HPnD

################################################################################
# rbX.local - Audience extension APs
################################################################################
# Set to a strong, random password. SSH is open to WAN!
:global passwd "W0lT3UISImum6BNsSySs"
:global identity "rb2.local"
# "America/Chicago", "America/Los_Angeles", etc.
:global timezone "America/Chicago"
:global extraUser "yottabit"
# Set to a strong, random password. SSH is open to WAN!
:global yottabitPassword "qy56pe5tpDZJCs085Q8c"
################################################################################

# This password will be disabled automatically when the SSH pubkey is added, but
# we assign a strong password here just for safety in case the SSH pubkey is
# forgotten or deleted.
/user
add name="$extraUser" group="full" password="$yottabitPassword"
# SSH will be open to the Internet; only allow password login from the LAN.
set [ find name=admin ] password="$passwd" address=192.168.88.0/24

/system clock
set time-zone-name="$timezone"

/system identity
set name="$identity"

/system script environment
remove [ find name="passwd" ]
remove [ find name="identity" ]
remove [ find name="timezone" ]
remove [ find name="yottabitPassword" ]
remove [ find name="extraUser" ]

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
/file remove [ find name="installBackupAndUpdate.rsc" ]

/interface wireless
set [ find default-name=wlan4 ] keepalive-frames=disabled wmm-support=enabled
set [ find default-name=wlan3 ] adaptive-noise-immunity=ap-and-client-mode \
    band=5ghz-onlyac channel-width=20/40/80mhz-XXXX disabled=no distance=\
    indoors frequency=auto keepalive-frames=disabled wmm-support=enabled

# Import the SSH pubkey.
