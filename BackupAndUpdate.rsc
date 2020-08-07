# aug/06/2020 18:56:50 by RouterOS 6.47.1
# software id = I1GP-C42D
#
# model = RBD25G-5HPacQD2HPnD
# serial number = BB0C0BAFB0E0
/system script
add dont-require-permissions=no name=BackupAndUpdate owner=admin policy=\
    policy,reboot,read,write,sensitive,test source="#\
    \_Script name: BackupAndUpdate\r\
    \n#\r\
    \n# Forked from https://github.com/beeyev at version 20.04.17 (2020-04-17)\
    .\r\
    \n# Minimum supported RouterOS version is v6.43.7\r\
    \n#\r\
    \n#----------MODIFY THIS SECTION AS NEEDED--------------------------------\
    --------\r\
    \n## Notification e-mail\r\
    \n## (Make sure you have configurated Email settings in Tools -> Email)\r\
    \n:local emailAddress \"yourmail@example.com\";\r\
    \n\r\
    \n## Script mode, possible values: backup, osupdate, osnotify.\r\
    \n# backup \t- \tOnly backup will be performed. (default value, if none pr\
    ovided)\r\
    \n#\r\
    \n# osupdate \t- \tThe Script will install a new RouterOS if it is availab\
    le.\r\
    \n#\t\t\t\tIt will also create backups before and after update process.\r\
    \n#\t\t\t\tEmail will be sent only if a new RouterOS is available.\r\
    \n#\t\t\t\tChange parameter `forceBackup` if you need the script to create\
    \_backups every time when it runs.\r\
    \n#\r\
    \n# osnotify \t- \tThe script will send email notification only (without b\
    ackups) if a new RouterOS is available.\r\
    \n#\t\t\t\tChange parameter `forceBackup` if you need the script to create\
    \_backups every time when it runs.\r\
    \n:local scriptMode \"osupdate\";\r\
    \n\r\
    \n## Additional parameter if you set `scriptMode` to `osupdate` or `osnoti\
    fy`\r\
    \n# Set `true` if you want the script to perform backup every time it's fi\
    red, whatever script mode is set.\r\
    \n:local forceBackup false;\r\
    \n\r\
    \n## Backup encryption password, no encryption if no password.\r\
    \n:local backupPassword \"\"\r\
    \n\r\
    \n## If true, passwords will be included in exported config.\r\
    \n:local sensetiveDataInConfig true;\r\
    \n\r\
    \n## Update channel. Possible values: stable, long-term, testing, developm\
    ent\r\
    \n:local updateChannel \"stable\";\r\
    \n\r\
    \n## Install only patch versions of RouterOS updates.\r\
    \n## Works only if you set scriptMode to \"osupdate\"\r\
    \n## Means that new update will be installed only if MAJOR and MINOR versi\
    on numbers remained the same as currently installed RouterOS.\r\
    \n## Example: v6.43.6 => major.minor.PATCH\r\
    \n## Script will send information if new version is greater than just patc\
    h.\r\
    \n:local installOnlyPatchUpdates\tfalse;\r\
    \n\r\
    \n##----------------------------------------------------------------------\
    --------------------##\r\
    \n#  !!!! DO NOT CHANGE ANYTHING BELOW THIS LINE, IF YOU ARE NOT SURE WHAT\
    \_YOU ARE DOING !!!!  #\r\
    \n##----------------------------------------------------------------------\
    --------------------##\r\
    \n\r\
    \n#Script messages prefix\r\
    \n:local SMP \"Bkp&Upd:\"\r\
    \n\r\
    \n:log info \"\\r\\n\$SMP script \\\"Mikrotik RouterOS automatic backup & \
    update\\\" started.\";\r\
    \n:log info \"\$SMP Script Mode: \$scriptMode, forceBackup: \$forceBackup\
    \";\r\
    \n\r\
    \n#Check proper email config\r\
    \n:if ([:len \$emailAddress] = 0 or [:len [/tool e-mail get address]] = 0 \
    or [:len [/tool e-mail get from]] = 0) do={\r\
    \n\t:log error (\"\$SMP Email configuration is not correct, please check T\
    ools -> Email.\");   \r\
    \n#\t:error \"\$SMP bye!\";\r\
    \n}\r\
    \n\r\
    \n#Check if proper identity name is set\r\
    \nif ([:len [/system identity get name]] = 0 or [/system identity get name\
    ] = \"MikroTik\") do={\r\
    \n\t:log warning (\"\$SMP Please set identity name of your device (System \
    -> Identity), keep it short and informative.\");  \r\
    \n};\r\
    \n\r\
    \n############### vvvvvvvvv GLOBALS vvvvvvvvv ###############\r\
    \n# Function converts standard mikrotik build versions to the number.\r\
    \n# Possible arguments: paramOsVer\r\
    \n# Example:\r\
    \n# :put [\$buGlobalFuncGetOsVerNum paramOsVer=[/system routerboard get cu\
    rrent-RouterOS]];\r\
    \n# result will be: 64301, because current RouterOS version is: 6.43.1\r\
    \n:global buGlobalFuncGetOsVerNum do={\r\
    \n\t:local osVer \$paramOsVer;\r\
    \n\t:local osVerNum;\r\
    \n\t:local osVerMicroPart;\r\
    \n\t:local zro 0;\r\
    \n\t:local tmp;\r\
    \n\t\r\
    \n\t# Replace word `beta` with dot\r\
    \n\t:local isBetaPos [:tonum [:find \$osVer \"beta\" 0]];\r\
    \n\t:if (\$isBetaPos > 1) do={\r\
    \n\t\t:set osVer ([:pick \$osVer 0 \$isBetaPos] . \".\" . [:pick \$osVer (\
    \$isBetaPos + 4) [:len \$osVer]]);\r\
    \n\t}\r\
    \n\t\r\
    \n\t:local dotPos1 [:find \$osVer \".\" 0];\r\
    \n\r\
    \n\t:if (\$dotPos1 > 0) do={ \r\
    \n\r\
    \n\t\t# AA\r\
    \n\t\t:set osVerNum  [:pick \$osVer 0 \$dotPos1];\r\
    \n\t\t\r\
    \n\t\t:local dotPos2 [:find \$osVer \".\" \$dotPos1];\r\
    \n\t\t\t\t#Taking minor version, everything after first dot\r\
    \n\t\t:if ([:len \$dotPos2] = 0) \tdo={:set tmp [:pick \$osVer (\$dotPos1+\
    1) [:len \$osVer]];}\r\
    \n\t\t#Taking minor version, everything between first and second dots\r\
    \n\t\t:if (\$dotPos2 > 0) \t\t\tdo={:set tmp [:pick \$osVer (\$dotPos1+1) \
    \$dotPos2];}\r\
    \n\t\t\r\
    \n\t\t# AA 0B\r\
    \n\t\t:if ([:len \$tmp] = 1) \tdo={:set osVerNum \"\$osVerNum\$zro\$tmp\";\
    }\r\
    \n\t\t# AA BB\r\
    \n\t\t:if ([:len \$tmp] = 2) \tdo={:set osVerNum \"\$osVerNum\$tmp\";}\r\
    \n\t\t\r\
    \n\t\t:if (\$dotPos2 > 0) do={ \r\
    \n\t\t\t:set tmp [:pick \$osVer (\$dotPos2+1) [:len \$osVer]];\r\
    \n\t\t\t# AA BB 0C\r\
    \n\t\t\t:if ([:len \$tmp] = 1) do={:set osVerNum \"\$osVerNum\$zro\$tmp\";\
    }\r\
    \n\t\t\t# AA BB CC\r\
    \n\t\t\t:if ([:len \$tmp] = 2) do={:set osVerNum \"\$osVerNum\$tmp\";}\r\
    \n\t\t} else={\r\
    \n\t\t\t# AA BB 00\r\
    \n\t\t\t:set osVerNum \"\$osVerNum\$zro\$zro\";\r\
    \n\t\t}\r\
    \n\t} else={\r\
    \n\t\t# AA 00 00\r\
    \n\t\t:set osVerNum \"\$osVer\$zro\$zro\$zro\$zro\";\r\
    \n\t}\r\
    \n\r\
    \n\t:return \$osVerNum;\r\
    \n}\r\
    \n\r\
    \n# Function creates backups (system and config) and returns array with na\
    mes\r\
    \n# Possible arguments: \r\
    \n#\t`backupName` \t\t\t| string\t| backup file name, without extension!\r\
    \n#\t`backupPassword`\t\t| string \t|\r\
    \n#\t`sensetiveDataInConfig`\t| boolean \t|\r\
    \n# Example:\r\
    \n# :put [\$buGlobalFuncCreateBackups name=\"daily-backup\"];\r\
    \n:global buGlobalFuncCreateBackups do={\r\
    \n\t:log info (\"\$SMP Global function \\\"buGlobalFuncCreateBackups\\\" w\
    as fired.\");  \r\
    \n\t\r\
    \n\t:local backupFileSys \"\$backupName.backup\";\r\
    \n\t:local backupFileConfig \"\$backupName.rsc\";\r\
    \n\t:local backupNames {\$backupFileSys;\$backupFileConfig};\r\
    \n\r\
    \n        ## Remove old backups if there is less than 3 MiB free space.\r\
    \n        :if ( [/system resource get free-hdd-space] < 3145728) do={\r\
    \n          /file\r\
    \n\t    remove [/file find name~\".backup\"]\r\
    \n\t    remove [/file find name~\"*.rsc\"]\r\
    \n\t}\r\
    \n\r\
    \n\t## Make system backup\r\
    \n\t:if ([:len \$backupPassword] = 0) do={\r\
    \n\t\t/system backup save dont-encrypt=yes name=\$backupName;\r\
    \n\t} else={\r\
    \n\t\t/system backup save password=\$backupPassword name=\$backupName;\r\
    \n\t}\r\
    \n\t:log info (\"\$SMP System backup created. \$backupFileSys\");   \r\
    \n\r\
    \n\t## Export config file\r\
    \n\t:if (\$sensetiveDataInConfig = true) do={\r\
    \n\t\t/export compact file=\$backupName;\r\
    \n\t} else={\r\
    \n\t\t/export compact hide-sensitive file=\$backupName;\r\
    \n\t}\r\
    \n\t:log info (\"\$SMP Config file was exported. \$backupFileConfig\");   \
    \r\
    \n\r\
    \n\t#Delay after creating backups\r\
    \n\t:delay 5s;\t\r\
    \n\t:return \$backupNames;\r\
    \n}\r\
    \n\r\
    \n:global buGlobalVarUpdateStep;\r\
    \n############### ^^^^^^^^^ GLOBALS ^^^^^^^^^ ###############\r\
    \n\r\
    \n#Current date time in format: 2020jan15-221324 \r\
    \n:local dateTime ([:pick [/system clock get date] 7 11] . [:pick [/system\
    \_clock get date] 0 3] . [:pick [/system clock get date] 4 6] . \"-\" . [:\
    pick [/system clock get time] 0 2] . [:pick [/system clock get time] 3 5] \
    . [:pick [/system clock get time] 6 8]);\r\
    \n\r\
    \n:local deviceOsVerInst \t\t\t[/system package update get installed-versi\
    on];\r\
    \n:local deviceOsVerInstNum \t\t[\$buGlobalFuncGetOsVerNum paramOsVer=\$de\
    viceOsVerInst];\r\
    \n:local deviceOsVerAvail \t\t\"\";\r\
    \n:local deviceOsVerAvailNum \t\t0;\r\
    \n:local deviceRbModel\t\t\t[/system routerboard get model];\r\
    \n:local deviceRbSerialNumber \t[/system routerboard get serial-number];\r\
    \n:local deviceRbCurrentFw \t\t[/system routerboard get current-firmware];\
    \r\
    \n:local deviceRbUpgradeFw \t\t[/system routerboard get upgrade-firmware];\
    \r\
    \n:local deviceIdentityName \t\t[/system identity get name];\r\
    \n:local deviceIdentityNameShort \t[:pick \$deviceIdentityName 0 18]\r\
    \n:local deviceUpdateChannel \t\t[/system package update get channel];\r\
    \n\r\
    \n:local isOsUpdateAvailable \tfalse;\r\
    \n:local isOsNeedsToBeUpdated\tfalse;\r\
    \n\r\
    \n:local isSendEmailRequired\ttrue;\r\
    \n:local isNeverSendEmail\t\ttrue;\r\
    \n\r\
    \n:local mailSubject   \t\t\"\$SMP Device - \$deviceIdentityNameShort.\";\
    \r\
    \n:local mailBody \t \t\t\"\";\r\
    \n\r\
    \n:local mailBodyDeviceInfo\t\"\\r\\n\\r\\nDevice information: \\r\\nIdent\
    ity: \$deviceIdentityName \\r\\nModel: \$deviceRbModel \\r\\nSerial number\
    : \$deviceRbSerialNumber \\r\\nCurrent RouterOS: \$deviceOsVerInst (\$[/sy\
    stem package update get channel]) \$[/system resource get build-time] \\r\
    \\nCurrent routerboard FW: \$deviceRbCurrentFw \\r\\nDevice uptime: \$[/sy\
    stem resource get uptime]\";\r\
    \n:local mailBodyCopyright \t\"\\r\\n\\r\\nMikrotik RouterOS automatic bac\
    kup & update \\r\\nhttps://github.com/beeyev/Mikrotik-RouterOS-automatic-b\
    ackup-and-update\";\r\
    \n:local changelogUrl\t\t\t(\"Check RouterOS changelog: https://mikrotik.c\
    om/download/changelogs/\" . \$updateChannel . \"-release-tree\");\r\
    \n\r\
    \n:local backupName \t\t\t\"\$deviceIdentityName.\$deviceRbModel.\$deviceR\
    bSerialNumber.v\$deviceOsVerInst.\$deviceUpdateChannel.\$dateTime\";\r\
    \n:local backupNameBeforeUpd\t\"backup_before_update_\$backupName\";\r\
    \n:local backupNameAfterUpd\t\"backup_after_update_\$backupName\";\r\
    \n\r\
    \n:local backupNameFinal\t\t\$backupName;\r\
    \n:local mailAttachments\t\t[:toarray \"\"];\r\
    \n\r\
    \n:local updateStep \$buGlobalVarUpdateStep;\r\
    \n:do {/system script environment remove buGlobalVarUpdateStep;} on-error=\
    {}\r\
    \n:if ([:len \$updateStep] = 0) do={\r\
    \n\t:set updateStep 1;\r\
    \n}\r\
    \n\r\
    \n\r\
    \n## \tSTEP ONE: Creating backups, checking for new RouterOs version and s\
    ending email with backups,\r\
    \n## \tsteps 2 and 3 are fired only if script is set to automatically upda\
    te device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 1) do={\r\
    \n\t:log info (\"\$SMP Performing the first step.\");   \r\
    \n\r\
    \n\t# Checking for new RouterOS version\r\
    \n\tif (\$scriptMode = \"osupdate\" or \$scriptMode = \"osnotify\") do={\r\
    \n\t\tlog info (\"\$SMP Checking for new RouterOS version. Current version\
    \_is: \$deviceOsVerInst\");\r\
    \n\t\t/system package update set channel=\$updateChannel;\r\
    \n\t\t/system package update check-for-updates;\r\
    \n\t\t:delay 5s;\r\
    \n\t\t:set deviceOsVerAvail [/system package update get latest-version];\r\
    \n\r\
    \n\t\t# If there is a problem getting information about available RouterOS\
    \_from server\r\
    \n\t\t:if ([:len \$deviceOsVerAvail] = 0) do={\r\
    \n\t\t\t:log warning (\"\$SMP There is a problem getting information about\
    \_new RouterOS from server.\");\r\
    \n\t\t\t:set mailSubject\t(\$mailSubject . \" Error: No data about new Rou\
    terOS!\")\r\
    \n\t\t\t:set mailBody \t\t(\$mailBody . \"Error occured! \\r\\nMikrotik co\
    uldn't get any information about new RouterOS from server! \\r\\nWatch add\
    itional information in device logs.\")\r\
    \n\t\t} else={\r\
    \n\t\t\t#Get numeric version of OS\r\
    \n\t\t\t:set deviceOsVerAvailNum [\$buGlobalFuncGetOsVerNum paramOsVer=\$d\
    eviceOsVerAvail];\r\
    \n\r\
    \n\t\t\t# Checking if OS on server is greater than installed one.\r\
    \n\t\t\t:if (\$deviceOsVerAvailNum > \$deviceOsVerInstNum) do={\r\
    \n\t\t\t\t:set isOsUpdateAvailable true;\r\
    \n\t\t\t\t:log info (\"\$SMP New RouterOS is available! \$deviceOsVerAvail\
    \");\r\
    \n\t\t\t} else={\r\
    \n\t\t\t\t:set isSendEmailRequired false;\r\
    \n\t\t\t\t:log info (\"\$SMP System is already up to date.\");\r\
    \n\t\t\t\t:set mailSubject (\$mailSubject . \" No new OS updates.\");\r\
    \n\t\t\t\t:set mailBody \t (\$mailBody . \"Your system is up to date.\");\
    \r\
    \n\t\t\t}\r\
    \n\t\t};\r\
    \n\t} else={\r\
    \n\t\t:set scriptMode \"backup\";\r\
    \n\t};\r\
    \n\r\
    \n\tif (\$forceBackup = true) do={\r\
    \n\t\t# In this case the script will always send email, because it has to \
    create backups\r\
    \n\t\t:set isSendEmailRequired true;\r\
    \n\t}\r\
    \n\r\
    \n\t# if new OS version is available to install\r\
    \n\tif (\$isOsUpdateAvailable = true and \$isSendEmailRequired = true) do=\
    {\r\
    \n\t\t# If we only need to notify about new available version\r\
    \n\t\tif (\$scriptMode = \"osnotify\") do={\r\
    \n\t\t\t:set mailSubject \t(\$mailSubject . \" New RouterOS is available! \
    v.\$deviceOsVerAvail.\")\r\
    \n\t\t\t:set mailBody \t\t(\$mailBody . \"New RouterOS version is availabl\
    e to install: v.\$deviceOsVerAvail (\$updateChannel) \\r\\n\$changelogUrl\
    \")\r\
    \n\t\t}\r\
    \n\r\
    \n\t\t# if we need to initiate RouterOs update process\r\
    \n\t\tif (\$scriptMode = \"osupdate\") do={\r\
    \n\t\t\t:set isOsNeedsToBeUpdated true;\r\
    \n\t\t\t# if we need to install only patch updates\r\
    \n\t\t\t:if (\$installOnlyPatchUpdates = true) do={\r\
    \n\t\t\t\t#Check if Major and Minor builds are the same.\r\
    \n\t\t\t\t:if ([:pick \$deviceOsVerInstNum 0 ([:len \$deviceOsVerInstNum]-\
    2)] = [:pick \$deviceOsVerAvailNum 0 ([:len \$deviceOsVerAvailNum]-2)]) do\
    ={\r\
    \n\t\t\t\t\t:log info (\"\$SMP New patch version of RouterOS firmware is a\
    vailable.\");   \r\
    \n\t\t\t\t} else={\r\
    \n\t\t\t\t\t:log info (\"\$SMP New major or minor version of RouterOS firm\
    ware is available. You need to update it manually.\");\r\
    \n\t\t\t\t\t:set mailSubject \t(\$mailSubject . \" New RouterOS: v.\$devic\
    eOsVerAvail needs to be installed manually.\");\r\
    \n\t\t\t\t\t:set mailBody \t\t(\$mailBody . \"New major or minor RouterOS \
    version is available to install: v.\$deviceOsVerAvail (\$updateChannel). \
    \\r\\nYou chose to automatically install only patch updates, so this major\
    \_update you need to install manually. \\r\\n\$changelogUrl\");\r\
    \n\t\t\t\t\t:set isOsNeedsToBeUpdated false;\r\
    \n\t\t\t\t}\r\
    \n\t\t\t}\r\
    \n\r\
    \n\t\t\t#Check again, because this variable could be changed during checki\
    ng for installing only patch updats\r\
    \n\t\t\tif (\$isOsNeedsToBeUpdated = true) do={\r\
    \n\t\t\t\t:log info (\"\$SMP New RouterOS is going to be installed! v.\$de\
    viceOsVerInst -> v.\$deviceOsVerAvail\");\r\
    \n\t\t\t\t:set mailSubject\t(\$mailSubject . \" New RouterOS is going to b\
    e installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail.\");\r\
    \n\t\t\t\t:set mailBody \t\t(\$mailBody . \"Your Mikrotik will be updated \
    to the new RouterOS version from v.\$deviceOsVerInst to v.\$deviceOsVerAva\
    il (Update channel: \$updateChannel) \\r\\nFinal report with the detailed \
    information will be sent when update process is completed. \\r\\nIf you ha\
    ve not received second email in the next 5 minutes, then probably somethin\
    g went wrong. (Check your device logs)\");\r\
    \n\t\t\t\t#!! There is more code connected to this part and first step at \
    the end of the script.\r\
    \n\t\t\t}\r\
    \n\t\t\r\
    \n\t\t}\r\
    \n\t}\r\
    \n\r\
    \n\t## Checking If the script needs to create a backup\r\
    \n\t:log info (\"\$SMP Checking If the script needs to create a backup.\")\
    ;\r\
    \n\tif (\$forceBackup = true or \$scriptMode = \"backup\" or \$isOsNeedsTo\
    BeUpdated = true) do={\r\
    \n\t\t:log info (\"\$SMP Creating system backups.\");\r\
    \n\t\tif (\$isOsNeedsToBeUpdated = true) do={\r\
    \n\t\t\t:set backupNameFinal \$backupNameBeforeUpd;\r\
    \n\t\t};\r\
    \n\t\tif (\$scriptMode != \"backup\") do={\r\
    \n\t\t\t:set mailBody (\$mailBody . \"\\r\\n\\r\\n\");\r\
    \n\t\t};\r\
    \n\r\
    \n\t\t:set mailSubject\t(\$mailSubject . \" Backup was created.\");\r\
    \n\t\t:set mailBody\t\t(\$mailBody . \"System backups were created and att\
    ached to this email.\");\r\
    \n\r\
    \n\t\t:set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backu\
    pNameFinal backupPassword=\$backupPassword sensetiveDataInConfig=\$senseti\
    veDataInConfig];\r\
    \n\t} else={\r\
    \n\t\t:log info (\"\$SMP There is no need to create a backup.\");\r\
    \n\t}\r\
    \n\r\
    \n\t# Combine fisrst step email\r\
    \n\t:set mailBody (\$mailBody . \$mailBodyDeviceInfo . \$mailBodyCopyright\
    );\r\
    \n}\r\
    \n\r\
    \n## \tSTEP TWO: (after first reboot) routerboard firmware upgrade\r\
    \n## \tsteps 2 and 3 are fired only if script is set to automatically upda\
    te device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 2) do={\r\
    \n\t:log info (\"\$SMP Performing the second step.\");   \r\
    \n\t## RouterOS is the latest, let's check for upgraded routerboard firmwa\
    re\r\
    \n\tif (\$deviceRbCurrentFw != \$deviceRbUpgradeFw) do={\r\
    \n\t\t:set isSendEmailRequired false;\r\
    \n\t\t:delay 10s;\r\
    \n\t\t:log info \"\$SMP Upgrading routerboard firmware from v.\$deviceRbCu\
    rrentFw to v.\$deviceRbUpgradeFw\";\r\
    \n\t\t## Start the upgrading process\r\
    \n\t\t/system routerboard upgrade;\r\
    \n\t\t## Wait until the upgrade is completed\r\
    \n\t\t:delay 5s;\r\
    \n\t\t:log info \"\$SMP routerboard upgrade process was completed, going t\
    o reboot in a moment!\";\r\
    \n\t\t## Set scheduled task to send final report on the next boot, task wi\
    ll be deleted when is is done. (That is why you should keep original scrip\
    t name)\r\
    \n\t\t/system schedule add name=BKPUPD-FINAL-REPORT-ON-NEXT-BOOT on-event=\
    \":delay 5s; /system scheduler remove BKPUPD-FINAL-REPORT-ON-NEXT-BOOT; :g\
    lobal buGlobalVarUpdateStep 3; :delay 10s; /system script run BackupAndUpd\
    ate;\" start-time=startup interval=0;\r\
    \n\t\t## Reboot system to boot with new firmware\r\
    \n\t\t/system reboot;\r\
    \n\t} else={\r\
    \n\t\t:log info \"\$SMP It appers that your routerboard is already up to d\
    ate, skipping this step.\";\r\
    \n\t\t:set updateStep 3;\r\
    \n\t};\r\
    \n}\r\
    \n\r\
    \n## \tSTEP THREE: Last step (after second reboot) sending final report\r\
    \n## \tsteps 2 and 3 are fired only if script is set to automatically upda\
    te device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 3) do={\r\
    \n\t:log info (\"\$SMP Performing the third step.\");   \r\
    \n\t:log info \"Bkp&Upd: RouterOS and routerboard upgrade process was comp\
    leted. New RouterOS version: v.\$deviceOsVerInst, routerboard firmware: v.\
    \$deviceRbCurrentFw.\";\r\
    \n\t## Small delay in case mikrotik needs some time to initialize connecti\
    ons\r\
    \n\t:log info \"\$SMP The final email with report and backups of upgraded \
    system will be sent in a minute.\";\r\
    \n\t:delay 1m;\r\
    \n\t:set mailSubject\t(\$mailSubject . \" RouterOS Upgrade is completed, n\
    ew version: v.\$deviceOsVerInst!\");\r\
    \n\t:set mailBody \t  \t\"RouterOS and routerboard upgrade process was com\
    pleted. \\r\\nNew RouterOS version: v.\$deviceOsVerInst, routerboard firmw\
    are: v.\$deviceRbCurrentFw. \\r\\n\$changelogUrl \\r\\n\\r\\nBackups of th\
    e upgraded system are in the attachment of this email.  \$mailBodyDeviceIn\
    fo \$mailBodyCopyright\";\r\
    \n\t:set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backupN\
    ameAfterUpd backupPassword=\$backupPassword sensetiveDataInConfig=\$senset\
    iveDataInConfig];\r\
    \n}\r\
    \n\r\
    \n# Remove functions from global environment to keep it fresh and clean.\r\
    \n:do {/system script environment remove buGlobalFuncGetOsVerNum;} on-erro\
    r={}\r\
    \n:do {/system script environment remove buGlobalFuncCreateBackups;} on-er\
    ror={}\r\
    \n\r\
    \n##\r\
    \n## SENDING EMAIL\r\
    \n##\r\
    \n# Trying to send email with backups in attachment.\r\
    \n\r\
    \n:if (\$isSendEmailRequired = true and \$isNeverSendEmail = false) do={\r\
    \n\t:log info \"\$SMP Sending email message, it will take around half a mi\
    nute...\";\r\
    \n\t:do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\$\
    mailBody file=\$mailAttachments;} on-error={\r\
    \n\t\t:delay 5s;\r\
    \n\t\t:log error \"\$SMP could not send email message (\$[/tool e-mail get\
    \_last-status]). Going to try it again in a while.\"\r\
    \n\r\
    \n\t\t:delay 5m;\r\
    \n\r\
    \n\t\t:do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\
    \$mailBody file=\$mailAttachments;} on-error={\r\
    \n\t\t\t:delay 5s;\r\
    \n\t\t\t:log error \"\$SMP could not send email message (\$[/tool e-mail g\
    et last-status]) for the second time.\"\r\
    \n\r\
    \n\t\t\tif (\$isOsNeedsToBeUpdated = true) do={\r\
    \n\t\t\t\t:set isOsNeedsToBeUpdated false;\r\
    \n\t\t\t\t:log warning \"\$SMP script is not goint to initialise update pr\
    ocess due to inability to send backups to email.\"\r\
    \n\t\t\t}\r\
    \n\t\t}\r\
    \n\t}\r\
    \n\r\
    \n\t:delay 30s;\r\
    \n\t\r\
    \n\t:if ([:len \$mailAttachments] > 0 and [/tool e-mail get last-status] =\
    \_\"succeeded\") do={\r\
    \n\t\t:log info \"\$SMP File system cleanup.\"\r\
    \n\t\t/file remove \$mailAttachments; \r\
    \n\t\t:delay 2s;\r\
    \n\t}\r\
    \n\t\r\
    \n}\r\
    \n\r\
    \n\r\
    \n# Fire RouterOs update process\r\
    \nif (\$isOsNeedsToBeUpdated = true) do={\r\
    \n\r\
    \n\t## Set scheduled task to upgrade routerboard firmware on the next boot\
    , task will be deleted when upgrade is done. (That is why you should keep \
    original script name)\r\
    \n\t/system schedule add name=BKPUPD-UPGRADE-ON-NEXT-BOOT on-event=\":dela\
    y 5s; /system scheduler remove BKPUPD-UPGRADE-ON-NEXT-BOOT; :global buGlob\
    alVarUpdateStep 2; :delay 10s; /system script run BackupAndUpdate;\" start\
    -time=startup interval=0;\r\
    \n   \r\
    \n   :log info \"\$SMP everything is ready to install new RouterOS, going \
    to reboot in a moment!\"\r\
    \n\t## command is reincarnation of the \"upgrade\" command - doing exactly\
    \_the same but under a different name\r\
    \n\t/system package update install;\r\
    \n}\r\
    \n\r\
    \n:log info \"\$SMP script \\\"Mikrotik RouterOS automatic backup & update\
    \\\" completed it's job.\\r\\n\";"
/system scheduler
add interval=1d name=BackupAndUpdate on-event=\
    "/system script run BackupAndUpdate;" policy=\
    policy,reboot,read,write,sensitive,test start-date=jan/01/1970 \
    start-time=03:00:00
