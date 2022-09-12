# aug/06/2020 18:56:50 by RouterOS 6.47.1
# model = RBD25G-5HPacQD2HPnD

###
# Run the following commands to auto-import this script:
# /tool fetch mode=https url="https://raw.githubusercontent.com/yottabit42/routeros/master/installBackupAndUpdate.rsc"
# /import file-name="installBackupAndUpdate.rsc"
# :delay 2
# /file remove [ find name="installBackupAndUpdate.rsc" ]
###

/system script
add name=BackupAndUpdate owner=admin policy=ftp,reboot,read,write,policy,test,sensitive source="# Script name: BackupAndUpdate\r\
    \n#\r\
    \n# Forked from https://github.com/beeyev at version 20.04.17 (2020-04-17).\r\
    \n# Minimum supported RouterOS version is v6.43.7\r\
    \n#\r\
    \n#----------MODIFY THIS SECTION AS NEEDED----------------------------------------\r\
    \n## Notification e-mail\r\
    \n## (Make sure you have configurated Email settings in Tools -> Email)\r\
    \n:local emailAddress \"yourmail@example.com\";\r\
    \n\r\
    \n## Script mode, possible values: backup, osupdate, osnotify.\r\
    \n# backup   -   Only backup will be performed. (default value, if none provided)\r\
    \n#\r\
    \n# osupdate   -   The Script will install a new RouterOS if it is available.\r\
    \n#        It will also create backups before and after update process.\r\
    \n#        Email will be sent only if a new RouterOS is available.\r\
    \n#        Change parameter `forceBackup` if you need the script to create backups every time when it runs.\r\
    \n#\r\
    \n# osnotify   -   The script will send email notification only (without backups) if a new RouterOS is available.\r\
    \n#        Change parameter `forceBackup` if you need the script to create backups every time when it runs.\r\
    \n:local scriptMode \"osupdate\";\r\
    \n\r\
    \n## Additional parameter if you set `scriptMode` to `osupdate` or `osnotify`\r\
    \n# Set `true` if you want the script to perform backup every time it's fired, whatever script mode is set.\r\
    \n:local forceBackup false;\r\
    \n\r\
    \n## Backup encryption password, no encryption if no password.\r\
    \n:local backupPassword \"\"\r\
    \n\r\
    \n## If true, passwords will be included in exported config.\r\
    \n:local sensetiveDataInConfig true;\r\
    \n\r\
    \n## Update channel. Possible values: stable, long-term, testing, development\r\
    \n:local updateChannel \"stable\";\r\
    \n\r\
    \n## Install only patch versions of RouterOS updates.\r\
    \n## Works only if you set scriptMode to \"osupdate\"\r\
    \n## Means that new update will be installed only if MAJOR and MINOR version numbers remained the same as currently installed RouterOS.\r\
    \n## Example: v6.43.6 => major.minor.PATCH\r\
    \n## Script will send information if new version is greater than just patch.\r\
    \n:local installOnlyPatchUpdates  false;\r\
    \n\r\
    \n##------------------------------------------------------------------------------------------##\r\
    \n#  !!!! DO NOT CHANGE ANYTHING BELOW THIS LINE, IF YOU ARE NOT SURE WHAT YOU ARE DOING !!!!  #\r\
    \n##------------------------------------------------------------------------------------------##\r\
    \n\r\
    \n#Script messages prefix\r\
    \n:local SMP \"Bkp&Upd:\"\r\
    \n\r\
    \n:log info \" script \\\"Mikrotik RouterOS automatic backup & update\\\" started.\";\r\
    \n:log info \"\$SMP Script Mode: \$scriptMode, forceBackup: \$forceBackup\";\r\
    \n\r\
    \n#Check proper email config\r\
    \n:if ([:len \$emailAddress] = 0 or [:len [/tool e-mail get address]] = 0 or [:len [/tool e-mail get from]] = 0) do={\r\
    \n  :log error (\"\$SMP Email configuration is not correct, please check Tools -> Email.\");   \r\
    \n#  :error \"\$SMP bye!\";\r\
    \n}\r\
    \n\r\
    \n#Check if proper identity name is set\r\
    \nif ([:len [/system identity get name]] = 0 or [/system identity get name] = \"MikroTik\") do={\r\
    \n  :log warning (\"\$SMP Please set identity name of your device (System -> Identity), keep it short and informative.\");  \r\
    \n};\r\
    \n\r\
    \n############### vvvvvvvvv GLOBALS vvvvvvvvv ###############\r\
    \n# Function converts standard mikrotik build versions to the number.\r\
    \n# Possible arguments: paramOsVer\r\
    \n# Example:\r\
    \n# :put [\$buGlobalFuncGetOsVerNum paramOsVer=[/system routerboard get current-RouterOS]];\r\
    \n# result will be: 64301, because current RouterOS version is: 6.43.1\r\
    \n:global buGlobalFuncGetOsVerNum do={\r\
    \n  :local osVer \$paramOsVer;\r\
    \n  :local osVerNum;\r\
    \n  :local osVerMicroPart;\r\
    \n  :local zro 0;\r\
    \n  :local tmp;\r\
    \n  \r\
    \n  # Replace word `beta` with dot\r\
    \n  :local isBetaPos [:tonum [:find \$osVer \"beta\" 0]];\r\
    \n  :if (\$isBetaPos > 1) do={\r\
    \n    :set osVer ([:pick \$osVer 0 \$isBetaPos] . \".\" . [:pick \$osVer (\$isBetaPos + 4) [:len \$osVer]]);\r\
    \n  }\r\
    \n  \r\
    \n  :local dotPos1 [:find \$osVer \".\" 0];\r\
    \n\r\
    \n  :if (\$dotPos1 > 0) do={ \r\
    \n\r\
    \n    # AA\r\
    \n    :set osVerNum  [:pick \$osVer 0 \$dotPos1];\r\
    \n    \r\
    \n    :local dotPos2 [:find \$osVer \".\" \$dotPos1];\r\
    \n        #Taking minor version, everything after first dot\r\
    \n    :if ([:len \$dotPos2] = 0)   do={:set tmp [:pick \$osVer (\$dotPos1+1) [:len \$osVer]];}\r\
    \n    #Taking minor version, everything between first and second dots\r\
    \n    :if (\$dotPos2 > 0)       do={:set tmp [:pick \$osVer (\$dotPos1+1) \$dotPos2];}\r\
    \n    \r\
    \n    # AA 0B\r\
    \n    :if ([:len \$tmp] = 1)   do={:set osVerNum \"\$osVerNum\$zro\$tmp\";}\r\
    \n    # AA BB\r\
    \n    :if ([:len \$tmp] = 2)   do={:set osVerNum \"\$osVerNum\$tmp\";}\r\
    \n    \r\
    \n    :if (\$dotPos2 > 0) do={ \r\
    \n      :set tmp [:pick \$osVer (\$dotPos2+1) [:len \$osVer]];\r\
    \n      # AA BB 0C\r\
    \n      :if ([:len \$tmp] = 1) do={:set osVerNum \"\$osVerNum\$zro\$tmp\";}\r\
    \n      # AA BB CC\r\
    \n      :if ([:len \$tmp] = 2) do={:set osVerNum \"\$osVerNum\$tmp\";}\r\
    \n    } else={\r\
    \n      # AA BB 00\r\
    \n      :set osVerNum \"\$osVerNum\$zro\$zro\";\r\
    \n    }\r\
    \n  } else={\r\
    \n    # AA 00 00\r\
    \n    :set osVerNum \"\$osVer\$zro\$zro\$zro\$zro\";\r\
    \n  }\r\
    \n\r\
    \n  :return \$osVerNum;\r\
    \n}\r\
    \n\r\
    \n# Function creates backups (system and config) and returns array with names\r\
    \n# Possible arguments: \r\
    \n#  `backupName`       | string  | backup file name, without extension!\r\
    \n#  `backupPassword`    | string   |\r\
    \n#  `sensetiveDataInConfig`  | boolean   |\r\
    \n# Example:\r\
    \n# :put [\$buGlobalFuncCreateBackups name=\"daily-backup\"];\r\
    \n:global buGlobalFuncCreateBackups do={\r\
    \n  :log info (\"\$SMP Global function \\\"buGlobalFuncCreateBackups\\\" was fired.\");  \r\
    \n  \r\
    \n  :local backupFileSys \"\$backupName.backup\";\r\
    \n  :local backupFileConfig \"\$backupName.rsc\";\r\
    \n  :local backupNames {\$backupFileSys;\$backupFileConfig};\r\
    \n\r\
    \n        ## Remove old backups if there is less than 3 MiB free space.\r\
    \n        :if ( [/system resource get free-hdd-space] < 3145728) do={\r\
    \n          /file\r\
    \n      remove [/file find name~\".backup\"]\r\
    \n      remove [/file find name~\".rsc\"]\r\
    \n  }\r\
    \n\r\
    \n  ## Make system backup\r\
    \n  :if ([:len \$backupPassword] = 0) do={\r\
    \n    :if ([ /file find name~\"flash\" ]) do={\r\
    \n      /system backup save dont-encrypt=yes name=(\"flash/\" . \$backupName);\r\
    \n    } else={\r\
    \n      /system backup save dont-encrypt=yes name=\$backupName;\r\
    \n    }\r\
    \n  } else={\r\
    \n    :if ([ /file find name~\"flash\" ]) do={\r\
    \n      /system backup save password=\$backupPassword name=(\"flash/\" . \$backupName);\r\
    \n    } else={\r\
    \n      /system backup save password=\$backupPassword name=\$backupName;\r\
    \n    }\r\
    \n  }\r\
    \n  :log info (\"\$SMP System backup created. \$backupFileSys\");   \r\
    \n\r\
    \n  ## Export config file\r\
    \n  :if (\$sensetiveDataInConfig = true) do={\r\
    \n    :if ([ /file find name~\"flash\" ]) do={\r\
    \n      /export compact file=(\"flash/\" . \$backupName);\r\
    \n    } else={\r\
    \n      /export compact file=\$backupName;\r\
    \n    }\r\
    \n  } else={\r\
    \n    :if ([ /file find name~\"flash\" ]) do={\r\
    \n      /export compact hide-sensitive file=(\"flash/\" . \$backupName);\r\
    \n    } else={\r\
    \n      /export compact hide-sensitive file=\$backupName;\r\
    \n    }\r\
    \n  }\r\
    \n  :log info (\"\$SMP Config file was exported. \$backupFileConfig\");   \r\
    \n\r\
    \n  #Delay after creating backups\r\
    \n  :delay 5s;  \r\
    \n  :return \$backupNames;\r\
    \n}\r\
    \n\r\
    \n:global buGlobalVarUpdateStep;\r\
    \n############### ^^^^^^^^^ GLOBALS ^^^^^^^^^ ###############\r\
    \n\r\
    \n#Current date time in format: 2020jan15-221324 \r\
    \n:local dateTime ([:pick [/system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4 6] . \"-\" . [:pick [/system clock get time] 0 2] . [:pick [/system c\
    lock get time] 3 5] . [:pick [/system clock get time] 6 8]);\r\
    \n\r\
    \n:local deviceOsVerInst       [/system package update get installed-version];\r\
    \n:local deviceOsVerInstNum     [\$buGlobalFuncGetOsVerNum paramOsVer=\$deviceOsVerInst];\r\
    \n:local deviceOsVerAvail     \"\";\r\
    \n:local deviceOsVerAvailNum     0;\r\
    \n:local deviceRbModel      [/system routerboard get model];\r\
    \n:local deviceRbSerialNumber   [/system routerboard get serial-number];\r\
    \n:local deviceRbCurrentFw     [/system routerboard get current-firmware];\r\
    \n:local deviceRbUpgradeFw     [/system routerboard get upgrade-firmware];\r\
    \n:local deviceIdentityName     [/system identity get name];\r\
    \n:local deviceIdentityNameShort   [:pick \$deviceIdentityName 0 18]\r\
    \n:local deviceUpdateChannel     [/system package update get channel];\r\
    \n\r\
    \n:local isOsUpdateAvailable   false;\r\
    \n:local isOsNeedsToBeUpdated  false;\r\
    \n\r\
    \n:local isSendEmailRequired  true;\r\
    \n:local isNeverSendEmail    true;\r\
    \n\r\
    \n:local mailSubject       \"\$SMP Device - \$deviceIdentityNameShort.\";\r\
    \n:local mailBody        \"\";\r\
    \n\r\
    \n:local mailBodyDeviceInfo  \"\\r\\n\\r\\nDevice information: \\r\\nIdentity: \$deviceIdentityName \\r\\nModel: \$deviceRbModel \\r\\nSerial number: \$deviceRbSerialNumber \\r\\nCurrent RouterOS: \$de\
    viceOsVerInst (\$[/system package update get channel]) \$[/system resource get build-time] \\r\\nCurrent routerboard FW: \$deviceRbCurrentFw \\r\\nDevice uptime: \$[/system resource get uptime]\";\r\
    \n:local mailBodyCopyright   \"\\r\\n\\r\\nMikrotik RouterOS automatic backup & update \\r\\nhttps://github.com/beeyev/Mikrotik-RouterOS-automatic-backup-and-update\";\r\
    \n:local changelogUrl      (\"Check RouterOS changelog: https://mikrotik.com/download/changelogs/\" . \$updateChannel . \"-release-tree\");\r\
    \n\r\
    \n:local backupName       \"\$deviceIdentityName.\$deviceRbModel.\$deviceRbSerialNumber.v\$deviceOsVerInst.\$deviceUpdateChannel.\$dateTime\";\r\
    \n:local backupNameBeforeUpd  \"backup_before_update_\$backupName\";\r\
    \n:local backupNameAfterUpd  \"backup_after_update_\$backupName\";\r\
    \n\r\
    \n:local backupNameFinal    \$backupName;\r\
    \n:local mailAttachments    [:toarray \"\"];\r\
    \n\r\
    \n:local updateStep \$buGlobalVarUpdateStep;\r\
    \n:do {/system script environment remove buGlobalVarUpdateStep;} on-error={}\r\
    \n:if ([:len \$updateStep] = 0) do={\r\
    \n  :set updateStep 1;\r\
    \n}\r\
    \n\r\
    \n\r\
    \n##   STEP ONE: Creating backups, checking for new RouterOs version and sending email with backups,\r\
    \n##   steps 2 and 3 are fired only if script is set to automatically update device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 1) do={\r\
    \n  :log info (\"\$SMP Performing the first step.\");   \r\
    \n\r\
    \n  # Checking for new RouterOS version\r\
    \n  if (\$scriptMode = \"osupdate\" or \$scriptMode = \"osnotify\") do={\r\
    \n    log info (\"\$SMP Checking for new RouterOS version. Current version is: \$deviceOsVerInst\");\r\
    \n    /system package update set channel=\$updateChannel;\r\
    \n    /system package update check-for-updates;\r\
    \n    :delay 5s;\r\
    \n    :set deviceOsVerAvail [/system package update get latest-version];\r\
    \n\r\
    \n    # If there is a problem getting information about available RouterOS from server\r\
    \n    :if ([:len \$deviceOsVerAvail] = 0) do={\r\
    \n      :log warning (\"\$SMP There is a problem getting information about new RouterOS from server.\");\r\
    \n      :set mailSubject  (\$mailSubject . \" Error: No data about new RouterOS!\")\r\
    \n      :set mailBody     (\$mailBody . \"Error occured! \\r\\nMikrotik couldn't get any information about new RouterOS from server! \\r\\nWatch additional information in device logs.\")\r\
    \n    } else={\r\
    \n      #Get numeric version of OS\r\
    \n      :set deviceOsVerAvailNum [\$buGlobalFuncGetOsVerNum paramOsVer=\$deviceOsVerAvail];\r\
    \n\r\
    \n      # Checking if OS on server is greater than installed one.\r\
    \n      :if (\$deviceOsVerAvailNum > \$deviceOsVerInstNum) do={\r\
    \n        :set isOsUpdateAvailable true;\r\
    \n        :log info (\"\$SMP New RouterOS is available! \$deviceOsVerAvail\");\r\
    \n      } else={\r\
    \n        :set isSendEmailRequired false;\r\
    \n        :log info (\"\$SMP System is already up to date.\");\r\
    \n        :set mailSubject (\$mailSubject . \" No new OS updates.\");\r\
    \n        :set mailBody    (\$mailBody . \"Your system is up to date.\");\r\
    \n      }\r\
    \n    };\r\
    \n  } else={\r\
    \n    :set scriptMode \"backup\";\r\
    \n  };\r\
    \n\r\
    \n  if (\$forceBackup = true) do={\r\
    \n    # In this case the script will always send email, because it has to create backups\r\
    \n    :set isSendEmailRequired true;\r\
    \n  }\r\
    \n\r\
    \n  # if new OS version is available to install\r\
    \n  if (\$isOsUpdateAvailable = true and \$isSendEmailRequired = true) do={\r\
    \n    # If we only need to notify about new available version\r\
    \n    if (\$scriptMode = \"osnotify\") do={\r\
    \n      :set mailSubject   (\$mailSubject . \" New RouterOS is available! v.\$deviceOsVerAvail.\")\r\
    \n      :set mailBody     (\$mailBody . \"New RouterOS version is available to install: v.\$deviceOsVerAvail (\$updateChannel) \\r\\n\$changelogUrl\")\r\
    \n    }\r\
    \n\r\
    \n    # if we need to initiate RouterOs update process\r\
    \n    if (\$scriptMode = \"osupdate\") do={\r\
    \n      :set isOsNeedsToBeUpdated true;\r\
    \n      # if we need to install only patch updates\r\
    \n      :if (\$installOnlyPatchUpdates = true) do={\r\
    \n        #Check if Major and Minor builds are the same.\r\
    \n        :if ([:pick \$deviceOsVerInstNum 0 ([:len \$deviceOsVerInstNum]-2)] = [:pick \$deviceOsVerAvailNum 0 ([:len \$deviceOsVerAvailNum]-2)]) do={\r\
    \n          :log info (\"\$SMP New patch version of RouterOS firmware is available.\");   \r\
    \n        } else={\r\
    \n          :log info (\"\$SMP New major or minor version of RouterOS firmware is available. You need to update it manually.\");\r\
    \n          :set mailSubject   (\$mailSubject . \" New RouterOS: v.\$deviceOsVerAvail needs to be installed manually.\");\r\
    \n          :set mailBody     (\$mailBody . \"New major or minor RouterOS version is available to install: v.\$deviceOsVerAvail (\$updateChannel). \\r\\nYou chose to automatically install only patch up\
    dates, so this major update you need to install manually. \\r\\n\$changelogUrl\");\r\
    \n          :set isOsNeedsToBeUpdated false;\r\
    \n        }\r\
    \n      }\r\
    \n\r\
    \n      #Check again, because this variable could be changed during checking for installing only patch updats\r\
    \n      if (\$isOsNeedsToBeUpdated = true) do={\r\
    \n        :log info (\"\$SMP New RouterOS is going to be installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail\");\r\
    \n        :set mailSubject  (\$mailSubject . \" New RouterOS is going to be installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail.\");\r\
    \n        :set mailBody     (\$mailBody . \"Your Mikrotik will be updated to the new RouterOS version from v.\$deviceOsVerInst to v.\$deviceOsVerAvail (Update channel: \$updateChannel) \\r\\nFinal repo\
    rt with the detailed information will be sent when update process is completed. \\r\\nIf you have not received second email in the next 5 minutes, then probably something went wrong. (Check your device\
    \_logs)\");\r\
    \n        #!! There is more code connected to this part and first step at the end of the script.\r\
    \n      }\r\
    \n    \r\
    \n    }\r\
    \n  }\r\
    \n\r\
    \n  ## Checking If the script needs to create a backup\r\
    \n  :log info (\"\$SMP Checking If the script needs to create a backup.\");\r\
    \n  if (\$forceBackup = true or \$scriptMode = \"backup\" or \$isOsNeedsToBeUpdated = true) do={\r\
    \n    :log info (\"\$SMP Creating system backups.\");\r\
    \n    if (\$isOsNeedsToBeUpdated = true) do={\r\
    \n      :set backupNameFinal \$backupNameBeforeUpd;\r\
    \n    };\r\
    \n    if (\$scriptMode != \"backup\") do={\r\
    \n      :set mailBody (\$mailBody . \"\\r\\n\\r\\n\");\r\
    \n    };\r\
    \n\r\
    \n    :set mailSubject  (\$mailSubject . \" Backup was created.\");\r\
    \n    :set mailBody    (\$mailBody . \"System backups were created and attached to this email.\");\r\
    \n\r\
    \n    :set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backupNameFinal backupPassword=\$backupPassword sensetiveDataInConfig=\$sensetiveDataInConfig];\r\
    \n  } else={\r\
    \n    :log info (\"\$SMP There is no need to create a backup.\");\r\
    \n  }\r\
    \n\r\
    \n  # Combine fisrst step email\r\
    \n  :set mailBody (\$mailBody . \$mailBodyDeviceInfo . \$mailBodyCopyright);\r\
    \n}\r\
    \n\r\
    \n##   STEP TWO: (after first reboot) routerboard firmware upgrade\r\
    \n##   steps 2 and 3 are fired only if script is set to automatically update device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 2) do={\r\
    \n  :log info (\"\$SMP Performing the second step.\");   \r\
    \n  ## RouterOS is the latest, let's check for upgraded routerboard firmware\r\
    \n  if (\$deviceRbCurrentFw != \$deviceRbUpgradeFw) do={\r\
    \n    :set isSendEmailRequired false;\r\
    \n    :delay 10s;\r\
    \n    :log info \"\$SMP Upgrading routerboard firmware from v.\$deviceRbCurrentFw to v.\$deviceRbUpgradeFw\";\r\
    \n    ## Start the upgrading process\r\
    \n    /system routerboard upgrade;\r\
    \n    ## Wait until the upgrade is completed\r\
    \n    :delay 5s;\r\
    \n    :log info \"\$SMP routerboard upgrade process was completed, going to reboot in a moment!\";\r\
    \n    ## Set scheduled task to send final report on the next boot, task will be deleted when is is done. (That is why you should keep original script name)\r\
    \n    /system schedule add name=BKPUPD-FINAL-REPORT-ON-NEXT-BOOT on-event=\":delay 5s; /system scheduler remove BKPUPD-FINAL-REPORT-ON-NEXT-BOOT; :global buGlobalVarUpdateStep 3; :delay 10s; /system sc\
    ript run BackupAndUpdate;\" start-time=startup interval=0;\r\
    \n    ## Reboot system to boot with new firmware\r\
    \n    /system reboot;\r\
    \n  } else={\r\
    \n    :log info \"\$SMP It appers that your routerboard is already up to date, skipping this step.\";\r\
    \n    :set updateStep 3;\r\
    \n  };\r\
    \n}\r\
    \n\r\
    \n##   STEP THREE: Last step (after second reboot) sending final report\r\
    \n##   steps 2 and 3 are fired only if script is set to automatically update device and if new RouterOs is available.\r\
    \n:if (\$updateStep = 3) do={\r\
    \n  :log info (\"\$SMP Performing the third step.\");   \r\
    \n  :log info \"Bkp&Upd: RouterOS and routerboard upgrade process was completed. New RouterOS version: v.\$deviceOsVerInst, routerboard firmware: v.\$deviceRbCurrentFw.\";\r\
    \n  ## Small delay in case mikrotik needs some time to initialize connections\r\
    \n  :log info \"\$SMP The final email with report and backups of upgraded system will be sent in a minute.\";\r\
    \n  :delay 1m;\r\
    \n  :set mailSubject  (\$mailSubject . \" RouterOS Upgrade is completed, new version: v.\$deviceOsVerInst!\");\r\
    \n  :set mailBody       \"RouterOS and routerboard upgrade process was completed. \\r\\nNew RouterOS version: v.\$deviceOsVerInst, routerboard firmware: v.\$deviceRbCurrentFw. \\r\\n\$changelogUrl \\r\
    \\n\\r\\nBackups of the upgraded system are in the attachment of this email.  \$mailBodyDeviceInfo \$mailBodyCopyright\";\r\
    \n  :set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backupNameAfterUpd backupPassword=\$backupPassword sensetiveDataInConfig=\$sensetiveDataInConfig];\r\
    \n}\r\
    \n\r\
    \n# Remove functions from global environment to keep it fresh and clean.\r\
    \n:do {/system script environment remove buGlobalFuncGetOsVerNum;} on-error={}\r\
    \n:do {/system script environment remove buGlobalFuncCreateBackups;} on-error={}\r\
    \n\r\
    \n##\r\
    \n## SENDING EMAIL\r\
    \n##\r\
    \n# Trying to send email with backups in attachment.\r\
    \n\r\
    \n:if (\$isSendEmailRequired = true and \$isNeverSendEmail = false) do={\r\
    \n  :log info \"\$SMP Sending email message, it will take around half a minute...\";\r\
    \n  :do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\$mailBody file=\$mailAttachments;} on-error={\r\
    \n    :delay 5s;\r\
    \n    :log error \"\$SMP could not send email message (\$[/tool e-mail get last-status]). Going to try it again in a while.\"\r\
    \n\r\
    \n    :delay 5m;\r\
    \n\r\
    \n    :do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\$mailBody file=\$mailAttachments;} on-error={\r\
    \n      :delay 5s;\r\
    \n      :log error \"\$SMP could not send email message (\$[/tool e-mail get last-status]) for the second time.\"\r\
    \n\r\
    \n      if (\$isOsNeedsToBeUpdated = true) do={\r\
    \n        :set isOsNeedsToBeUpdated false;\r\
    \n        :log warning \"\$SMP script is not goint to initialise update process due to inability to send backups to email.\"\r\
    \n      }\r\
    \n    }\r\
    \n  }\r\
    \n\r\
    \n  :delay 30s;\r\
    \n  \r\
    \n  :if ([:len \$mailAttachments] > 0 and [/tool e-mail get last-status] = \"succeeded\") do={\r\
    \n    :log info \"\$SMP File system cleanup.\"\r\
    \n    /file remove \$mailAttachments; \r\
    \n    :delay 2s;\r\
    \n  }\r\
    \n  \r\
    \n}\r\
    \n\r\
    \n\r\
    \n# Fire RouterOs update process\r\
    \nif (\$isOsNeedsToBeUpdated = true) do={\r\
    \n\r\
    \n  ## Set scheduled task to upgrade routerboard firmware on the next boot, task will be deleted when upgrade is done. (That is why you should keep original script name)\r\
    \n  /system schedule add name=BKPUPD-UPGRADE-ON-NEXT-BOOT on-event=\":delay 5s; /system scheduler remove BKPUPD-UPGRADE-ON-NEXT-BOOT; :global buGlobalVarUpdateStep 2; :delay 10s; /system script run Bac\
    kupAndUpdate;\" start-time=startup interval=0;\r\
    \n   \r\
    \n   :log info \"\$SMP everything is ready to install new RouterOS, going to reboot in a moment!\"\r\
    \n  ## command is reincarnation of the \"upgrade\" command - doing exactly the same but under a different name\r\
    \n  /system package update install;\r\
    \n}\r\
    \n\r\
    \n:log info \"\$SMP script \\\"Mikrotik RouterOS automatic backup & update\\\" completed its job.\";"
/system scheduler
add interval=1d name=BackupAndUpdate on-event=\
    "/system script run BackupAndUpdate;" policy=\
    ftp,policy,reboot,read,write,sensitive,test start-date=jan/01/1970 \
    start-time=03:00:00
;
