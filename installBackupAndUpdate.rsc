# aug/06/2020 18:56:50 by RouterOS 6.47.1
# software id = I1GP-C42D
#
# model = RBD25G-5HPacQD2HPnD
# serial number = BB0C0BAFB0E0
/system script
add dont-require-permissions=no name=BackupAndUpdate owner=admin policy=ftp,reboot,read,write,policy,test,sensitive source="# Script name: BackupAndUpdate\
    \n#\
    \n# Forked from https://github.com/beeyev at version 20.04.17 (2020-04-17).\
    \n# Minimum supported RouterOS version is v6.43.7\
    \n#\
    \n#----------MODIFY THIS SECTION AS NEEDED----------------------------------------\
    \n## Notification e-mail\
    \n## (Make sure you have configurated Email settings in Tools -> Email)\
    \n:local emailAddress \"yourmail@example.com\";\
    \n\
    \n## Script mode, possible values: backup, osupdate, osnotify.\
    \n# backup   -   Only backup will be performed. (default value, if none provided)\
    \n#\
    \n# osupdate   -   The Script will install a new RouterOS if it is available.\
    \n#        It will also create backups before and after update process.\
    \n#        Email will be sent only if a new RouterOS is available.\
    \n#        Change parameter `forceBackup` if you need the script to create backups every time when it runs.\
    \n#\
    \n# osnotify   -   The script will send email notification only (without backups) if a new RouterOS is available.\
    \n#        Change parameter `forceBackup` if you need the script to create backups every time when it runs.\
    \n:local scriptMode \"osupdate\";\
    \n\
    \n## Additional parameter if you set `scriptMode` to `osupdate` or `osnotify`\
    \n# Set `true` if you want the script to perform backup every time it's fired, whatever script mode is set.\
    \n:local forceBackup false;\
    \n\
    \n## Backup encryption password, no encryption if no password.\
    \n:local backupPassword \"\"\
    \n\
    \n## If true, passwords will be included in exported config.\
    \n:local sensetiveDataInConfig true;\
    \n\
    \n## Update channel. Possible values: stable, long-term, testing, development\
    \n:local updateChannel \"stable\";\
    \n\
    \n## Install only patch versions of RouterOS updates.\
    \n## Works only if you set scriptMode to \"osupdate\"\
    \n## Means that new update will be installed only if MAJOR and MINOR version numbers remained the same as currently installed RouterOS.\
    \n## Example: v6.43.6 => major.minor.PATCH\
    \n## Script will send information if new version is greater than just patch.\
    \n:local installOnlyPatchUpdates  false;\
    \n\
    \n##------------------------------------------------------------------------------------------##\
    \n#  !!!! DO NOT CHANGE ANYTHING BELOW THIS LINE, IF YOU ARE NOT SURE WHAT YOU ARE DOING !!!!  #\
    \n##------------------------------------------------------------------------------------------##\
    \n\
    \n#Script messages prefix\
    \n:local SMP \"Bkp&Upd:\"\
    \n\
    \n:log info \" script \\\"Mikrotik RouterOS automatic backup & update\\\" started.\";\
    \n:log info \"\$SMP Script Mode: \$scriptMode, forceBackup: \$forceBackup\";\
    \n\
    \n#Check proper email config\
    \n:if ([:len \$emailAddress] = 0 or [:len [/tool e-mail get address]] = 0 or [:len [/tool e-mail get from]] = 0) do={\
    \n  :log error (\"\$SMP Email configuration is not correct, please check Tools -> Email.\");   \
    \n#  :error \"\$SMP bye!\";\
    \n}\
    \n\
    \n#Check if proper identity name is set\
    \nif ([:len [/system identity get name]] = 0 or [/system identity get name] = \"MikroTik\") do={\
    \n  :log warning (\"\$SMP Please set identity name of your device (System -> Identity), keep it short and informative.\");  \
    \n};\
    \n\
    \n############### vvvvvvvvv GLOBALS vvvvvvvvv ###############\
    \n# Function converts standard mikrotik build versions to the number.\
    \n# Possible arguments: paramOsVer\
    \n# Example:\
    \n# :put [\$buGlobalFuncGetOsVerNum paramOsVer=[/system routerboard get current-RouterOS]];\
    \n# result will be: 64301, because current RouterOS version is: 6.43.1\
    \n:global buGlobalFuncGetOsVerNum do={\
    \n  :local osVer \$paramOsVer;\
    \n  :local osVerNum;\
    \n  :local osVerMicroPart;\
    \n  :local zro 0;\
    \n  :local tmp;\
    \n  \
    \n  # Replace word `beta` with dot\
    \n  :local isBetaPos [:tonum [:find \$osVer \"beta\" 0]];\
    \n  :if (\$isBetaPos > 1) do={\
    \n    :set osVer ([:pick \$osVer 0 \$isBetaPos] . \".\" . [:pick \$osVer (\$isBetaPos + 4) [:len \$osVer]]);\
    \n  }\
    \n  \
    \n  :local dotPos1 [:find \$osVer \".\" 0];\
    \n\
    \n  :if (\$dotPos1 > 0) do={ \
    \n\
    \n    # AA\
    \n    :set osVerNum  [:pick \$osVer 0 \$dotPos1];\
    \n    \
    \n    :local dotPos2 [:find \$osVer \".\" \$dotPos1];\
    \n        #Taking minor version, everything after first dot\
    \n    :if ([:len \$dotPos2] = 0)   do={:set tmp [:pick \$osVer (\$dotPos1+1) [:len \$osVer]];}\
    \n    #Taking minor version, everything between first and second dots\
    \n    :if (\$dotPos2 > 0)       do={:set tmp [:pick \$osVer (\$dotPos1+1) \$dotPos2];}\
    \n    \
    \n    # AA 0B\
    \n    :if ([:len \$tmp] = 1)   do={:set osVerNum \"\$osVerNum\$zro\$tmp\";}\
    \n    # AA BB\
    \n    :if ([:len \$tmp] = 2)   do={:set osVerNum \"\$osVerNum\$tmp\";}\
    \n    \
    \n    :if (\$dotPos2 > 0) do={ \
    \n      :set tmp [:pick \$osVer (\$dotPos2+1) [:len \$osVer]];\
    \n      # AA BB 0C\
    \n      :if ([:len \$tmp] = 1) do={:set osVerNum \"\$osVerNum\$zro\$tmp\";}\
    \n      # AA BB CC\
    \n      :if ([:len \$tmp] = 2) do={:set osVerNum \"\$osVerNum\$tmp\";}\
    \n    } else={\
    \n      # AA BB 00\
    \n      :set osVerNum \"\$osVerNum\$zro\$zro\";\
    \n    }\
    \n  } else={\
    \n    # AA 00 00\
    \n    :set osVerNum \"\$osVer\$zro\$zro\$zro\$zro\";\
    \n  }\
    \n\
    \n  :return \$osVerNum;\
    \n}\
    \n\
    \n# Function creates backups (system and config) and returns array with names\
    \n# Possible arguments: \
    \n#  `backupName`       | string  | backup file name, without extension!\
    \n#  `backupPassword`    | string   |\
    \n#  `sensetiveDataInConfig`  | boolean   |\
    \n# Example:\
    \n# :put [\$buGlobalFuncCreateBackups name=\"daily-backup\"];\
    \n:global buGlobalFuncCreateBackups do={\
    \n  :log info (\"\$SMP Global function \\\"buGlobalFuncCreateBackups\\\" was fired.\");  \
    \n  \
    \n  :local backupFileSys \"\$backupName.backup\";\
    \n  :local backupFileConfig \"\$backupName.rsc\";\
    \n  :local backupNames {\$backupFileSys;\$backupFileConfig};\
    \n\
    \n        ## Remove old backups if there is less than 3 MiB free space.\
    \n        :if ( [/system resource get free-hdd-space] < 3145728) do={\
    \n          /file\
    \n      remove [/file find name~\".backup\"]\
    \n      remove [/file find name~\"*.rsc\"]\
    \n  }\
    \n\
    \n  ## Make system backup\
    \n  :if ([:len \$backupPassword] = 0) do={\
    \n    :if ([ /file find name~\"flash\" ]) do={\
    \n      /system backup save dont-encrypt=yes name=(\"flash/\" . \$backupName);\
    \n    } else={\
    \n      /system backup save dont-encrypt=yes name=\$backupName;\
    \n    }\
    \n  } else={\
    \n    :if ([ /file find name~\"flash\" ]) do={\
    \n      /system backup save password=\$backupPassword name=(\"flash/\" . \$backupName);\
    \n    } else={\
    \n      /system backup save password=\$backupPassword name=\$backupName;\
    \n    }\
    \n  }\
    \n  :log info (\"\$SMP System backup created. \$backupFileSys\");   \
    \n\
    \n  ## Export config file\
    \n  :if (\$sensetiveDataInConfig = true) do={\
    \n    /export compact file=\$backupName;\
    \n  } else={\
    \n    /export compact hide-sensitive file=\$backupName;\
    \n  }\
    \n  :log info (\"\$SMP Config file was exported. \$backupFileConfig\");   \
    \n\
    \n  #Delay after creating backups\
    \n  :delay 5s;  \
    \n  :return \$backupNames;\
    \n}\
    \n\
    \n:global buGlobalVarUpdateStep;\
    \n############### ^^^^^^^^^ GLOBALS ^^^^^^^^^ ###############\
    \n\
    \n#Current date time in format: 2020jan15-221324 \
    \n:local dateTime ([:pick [/system clock get date] 7 11] . [:pick [/system clock get date] 0 3] . [:pick [/system clock get date] 4 6] . \"-\" . [:pick [/system clock get time] 0 2] . [:pick [/system c\
    lock get time] 3 5] . [:pick [/system clock get time] 6 8]);\
    \n\
    \n:local deviceOsVerInst       [/system package update get installed-version];\
    \n:local deviceOsVerInstNum     [\$buGlobalFuncGetOsVerNum paramOsVer=\$deviceOsVerInst];\
    \n:local deviceOsVerAvail     \"\";\
    \n:local deviceOsVerAvailNum     0;\
    \n:local deviceRbModel      [/system routerboard get model];\
    \n:local deviceRbSerialNumber   [/system routerboard get serial-number];\
    \n:local deviceRbCurrentFw     [/system routerboard get current-firmware];\
    \n:local deviceRbUpgradeFw     [/system routerboard get upgrade-firmware];\
    \n:local deviceIdentityName     [/system identity get name];\
    \n:local deviceIdentityNameShort   [:pick \$deviceIdentityName 0 18]\
    \n:local deviceUpdateChannel     [/system package update get channel];\
    \n\
    \n:local isOsUpdateAvailable   false;\
    \n:local isOsNeedsToBeUpdated  false;\
    \n\
    \n:local isSendEmailRequired  true;\
    \n:local isNeverSendEmail    true;\
    \n\
    \n:local mailSubject       \"\$SMP Device - \$deviceIdentityNameShort.\";\
    \n:local mailBody        \"\";\
    \n\
    \n:local mailBodyDeviceInfo  \"\\r\\n\\r\\nDevice information: \\r\\nIdentity: \$deviceIdentityName \\r\\nModel: \$deviceRbModel \\r\\nSerial number: \$deviceRbSerialNumber \\r\\nCurrent RouterOS: \$de\
    viceOsVerInst (\$[/system package update get channel]) \$[/system resource get build-time] \\r\\nCurrent routerboard FW: \$deviceRbCurrentFw \\r\\nDevice uptime: \$[/system resource get uptime]\";\
    \n:local mailBodyCopyright   \"\\r\\n\\r\\nMikrotik RouterOS automatic backup & update \\r\\nhttps://github.com/beeyev/Mikrotik-RouterOS-automatic-backup-and-update\";\
    \n:local changelogUrl      (\"Check RouterOS changelog: https://mikrotik.com/download/changelogs/\" . \$updateChannel . \"-release-tree\");\
    \n\
    \n:local backupName       \"\$deviceIdentityName.\$deviceRbModel.\$deviceRbSerialNumber.v\$deviceOsVerInst.\$deviceUpdateChannel.\$dateTime\";\
    \n:local backupNameBeforeUpd  \"backup_before_update_\$backupName\";\
    \n:local backupNameAfterUpd  \"backup_after_update_\$backupName\";\
    \n\
    \n:local backupNameFinal    \$backupName;\
    \n:local mailAttachments    [:toarray \"\"];\
    \n\
    \n:local updateStep \$buGlobalVarUpdateStep;\
    \n:do {/system script environment remove buGlobalVarUpdateStep;} on-error={}\
    \n:if ([:len \$updateStep] = 0) do={\
    \n  :set updateStep 1;\
    \n}\
    \n\
    \n\
    \n##   STEP ONE: Creating backups, checking for new RouterOs version and sending email with backups,\
    \n##   steps 2 and 3 are fired only if script is set to automatically update device and if new RouterOs is available.\
    \n:if (\$updateStep = 1) do={\
    \n  :log info (\"\$SMP Performing the first step.\");   \
    \n\
    \n  # Checking for new RouterOS version\
    \n  if (\$scriptMode = \"osupdate\" or \$scriptMode = \"osnotify\") do={\
    \n    log info (\"\$SMP Checking for new RouterOS version. Current version is: \$deviceOsVerInst\");\
    \n    /system package update set channel=\$updateChannel;\
    \n    /system package update check-for-updates;\
    \n    :delay 5s;\
    \n    :set deviceOsVerAvail [/system package update get latest-version];\
    \n\
    \n    # If there is a problem getting information about available RouterOS from server\
    \n    :if ([:len \$deviceOsVerAvail] = 0) do={\
    \n      :log warning (\"\$SMP There is a problem getting information about new RouterOS from server.\");\
    \n      :set mailSubject  (\$mailSubject . \" Error: No data about new RouterOS!\")\
    \n      :set mailBody     (\$mailBody . \"Error occured! \\r\\nMikrotik couldn't get any information about new RouterOS from server! \\r\\nWatch additional information in device logs.\")\
    \n    } else={\
    \n      #Get numeric version of OS\
    \n      :set deviceOsVerAvailNum [\$buGlobalFuncGetOsVerNum paramOsVer=\$deviceOsVerAvail];\
    \n\
    \n      # Checking if OS on server is greater than installed one.\
    \n      :if (\$deviceOsVerAvailNum > \$deviceOsVerInstNum) do={\
    \n        :set isOsUpdateAvailable true;\
    \n        :log info (\"\$SMP New RouterOS is available! \$deviceOsVerAvail\");\
    \n      } else={\
    \n        :set isSendEmailRequired false;\
    \n        :log info (\"\$SMP System is already up to date.\");\
    \n        :set mailSubject (\$mailSubject . \" No new OS updates.\");\
    \n        :set mailBody    (\$mailBody . \"Your system is up to date.\");\
    \n      }\
    \n    };\
    \n  } else={\
    \n    :set scriptMode \"backup\";\
    \n  };\
    \n\
    \n  if (\$forceBackup = true) do={\
    \n    # In this case the script will always send email, because it has to create backups\
    \n    :set isSendEmailRequired true;\
    \n  }\
    \n\
    \n  # if new OS version is available to install\
    \n  if (\$isOsUpdateAvailable = true and \$isSendEmailRequired = true) do={\
    \n    # If we only need to notify about new available version\
    \n    if (\$scriptMode = \"osnotify\") do={\
    \n      :set mailSubject   (\$mailSubject . \" New RouterOS is available! v.\$deviceOsVerAvail.\")\
    \n      :set mailBody     (\$mailBody . \"New RouterOS version is available to install: v.\$deviceOsVerAvail (\$updateChannel) \\r\\n\$changelogUrl\")\
    \n    }\
    \n\
    \n    # if we need to initiate RouterOs update process\
    \n    if (\$scriptMode = \"osupdate\") do={\
    \n      :set isOsNeedsToBeUpdated true;\
    \n      # if we need to install only patch updates\
    \n      :if (\$installOnlyPatchUpdates = true) do={\
    \n        #Check if Major and Minor builds are the same.\
    \n        :if ([:pick \$deviceOsVerInstNum 0 ([:len \$deviceOsVerInstNum]-2)] = [:pick \$deviceOsVerAvailNum 0 ([:len \$deviceOsVerAvailNum]-2)]) do={\
    \n          :log info (\"\$SMP New patch version of RouterOS firmware is available.\");   \
    \n        } else={\
    \n          :log info (\"\$SMP New major or minor version of RouterOS firmware is available. You need to update it manually.\");\
    \n          :set mailSubject   (\$mailSubject . \" New RouterOS: v.\$deviceOsVerAvail needs to be installed manually.\");\
    \n          :set mailBody     (\$mailBody . \"New major or minor RouterOS version is available to install: v.\$deviceOsVerAvail (\$updateChannel). \\r\\nYou chose to automatically install only patch up\
    dates, so this major update you need to install manually. \\r\\n\$changelogUrl\");\
    \n          :set isOsNeedsToBeUpdated false;\
    \n        }\
    \n      }\
    \n\
    \n      #Check again, because this variable could be changed during checking for installing only patch updats\
    \n      if (\$isOsNeedsToBeUpdated = true) do={\
    \n        :log info (\"\$SMP New RouterOS is going to be installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail\");\
    \n        :set mailSubject  (\$mailSubject . \" New RouterOS is going to be installed! v.\$deviceOsVerInst -> v.\$deviceOsVerAvail.\");\
    \n        :set mailBody     (\$mailBody . \"Your Mikrotik will be updated to the new RouterOS version from v.\$deviceOsVerInst to v.\$deviceOsVerAvail (Update channel: \$updateChannel) \\r\\nFinal repo\
    rt with the detailed information will be sent when update process is completed. \\r\\nIf you have not received second email in the next 5 minutes, then probably something went wrong. (Check your device\
    \_logs)\");\
    \n        #!! There is more code connected to this part and first step at the end of the script.\
    \n      }\
    \n    \
    \n    }\
    \n  }\
    \n\
    \n  ## Checking If the script needs to create a backup\
    \n  :log info (\"\$SMP Checking If the script needs to create a backup.\");\
    \n  if (\$forceBackup = true or \$scriptMode = \"backup\" or \$isOsNeedsToBeUpdated = true) do={\
    \n    :log info (\"\$SMP Creating system backups.\");\
    \n    if (\$isOsNeedsToBeUpdated = true) do={\
    \n      :set backupNameFinal \$backupNameBeforeUpd;\
    \n    };\
    \n    if (\$scriptMode != \"backup\") do={\
    \n      :set mailBody (\$mailBody . \"\\r\\n\\r\\n\");\
    \n    };\
    \n\
    \n    :set mailSubject  (\$mailSubject . \" Backup was created.\");\
    \n    :set mailBody    (\$mailBody . \"System backups were created and attached to this email.\");\
    \n\
    \n    :set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backupNameFinal backupPassword=\$backupPassword sensetiveDataInConfig=\$sensetiveDataInConfig];\
    \n  } else={\
    \n    :log info (\"\$SMP There is no need to create a backup.\");\
    \n  }\
    \n\
    \n  # Combine fisrst step email\
    \n  :set mailBody (\$mailBody . \$mailBodyDeviceInfo . \$mailBodyCopyright);\
    \n}\
    \n\
    \n##   STEP TWO: (after first reboot) routerboard firmware upgrade\
    \n##   steps 2 and 3 are fired only if script is set to automatically update device and if new RouterOs is available.\
    \n:if (\$updateStep = 2) do={\
    \n  :log info (\"\$SMP Performing the second step.\");   \
    \n  ## RouterOS is the latest, let's check for upgraded routerboard firmware\
    \n  if (\$deviceRbCurrentFw != \$deviceRbUpgradeFw) do={\
    \n    :set isSendEmailRequired false;\
    \n    :delay 10s;\
    \n    :log info \"\$SMP Upgrading routerboard firmware from v.\$deviceRbCurrentFw to v.\$deviceRbUpgradeFw\";\
    \n    ## Start the upgrading process\
    \n    /system routerboard upgrade;\
    \n    ## Wait until the upgrade is completed\
    \n    :delay 5s;\
    \n    :log info \"\$SMP routerboard upgrade process was completed, going to reboot in a moment!\";\
    \n    ## Set scheduled task to send final report on the next boot, task will be deleted when is is done. (That is why you should keep original script name)\
    \n    /system schedule add name=BKPUPD-FINAL-REPORT-ON-NEXT-BOOT on-event=\":delay 5s; /system scheduler remove BKPUPD-FINAL-REPORT-ON-NEXT-BOOT; :global buGlobalVarUpdateStep 3; :delay 10s; /system sc\
    ript run BackupAndUpdate;\" start-time=startup interval=0;\
    \n    ## Reboot system to boot with new firmware\
    \n    /system reboot;\
    \n  } else={\
    \n    :log info \"\$SMP It appers that your routerboard is already up to date, skipping this step.\";\
    \n    :set updateStep 3;\
    \n  };\
    \n}\
    \n\
    \n##   STEP THREE: Last step (after second reboot) sending final report\
    \n##   steps 2 and 3 are fired only if script is set to automatically update device and if new RouterOs is available.\
    \n:if (\$updateStep = 3) do={\
    \n  :log info (\"\$SMP Performing the third step.\");   \
    \n  :log info \"Bkp&Upd: RouterOS and routerboard upgrade process was completed. New RouterOS version: v.\$deviceOsVerInst, routerboard firmware: v.\$deviceRbCurrentFw.\";\
    \n  ## Small delay in case mikrotik needs some time to initialize connections\
    \n  :log info \"\$SMP The final email with report and backups of upgraded system will be sent in a minute.\";\
    \n  :delay 1m;\
    \n  :set mailSubject  (\$mailSubject . \" RouterOS Upgrade is completed, new version: v.\$deviceOsVerInst!\");\
    \n  :set mailBody       \"RouterOS and routerboard upgrade process was completed. \\r\\nNew RouterOS version: v.\$deviceOsVerInst, routerboard firmware: v.\$deviceRbCurrentFw. \\r\\n\$changelogUrl \\r\
    \\n\\r\\nBackups of the upgraded system are in the attachment of this email.  \$mailBodyDeviceInfo \$mailBodyCopyright\";\
    \n  :set mailAttachments [\$buGlobalFuncCreateBackups backupName=\$backupNameAfterUpd backupPassword=\$backupPassword sensetiveDataInConfig=\$sensetiveDataInConfig];\
    \n}\
    \n\
    \n# Remove functions from global environment to keep it fresh and clean.\
    \n:do {/system script environment remove buGlobalFuncGetOsVerNum;} on-error={}\
    \n:do {/system script environment remove buGlobalFuncCreateBackups;} on-error={}\
    \n\
    \n##\
    \n## SENDING EMAIL\
    \n##\
    \n# Trying to send email with backups in attachment.\
    \n\
    \n:if (\$isSendEmailRequired = true and \$isNeverSendEmail = false) do={\
    \n  :log info \"\$SMP Sending email message, it will take around half a minute...\";\
    \n  :do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\$mailBody file=\$mailAttachments;} on-error={\
    \n    :delay 5s;\
    \n    :log error \"\$SMP could not send email message (\$[/tool e-mail get last-status]). Going to try it again in a while.\"\
    \n\
    \n    :delay 5m;\
    \n\
    \n    :do {/tool e-mail send to=\$emailAddress subject=\$mailSubject body=\$mailBody file=\$mailAttachments;} on-error={\
    \n      :delay 5s;\
    \n      :log error \"\$SMP could not send email message (\$[/tool e-mail get last-status]) for the second time.\"\
    \n\
    \n      if (\$isOsNeedsToBeUpdated = true) do={\
    \n        :set isOsNeedsToBeUpdated false;\
    \n        :log warning \"\$SMP script is not goint to initialise update process due to inability to send backups to email.\"\
    \n      }\
    \n    }\
    \n  }\
    \n\
    \n  :delay 30s;\
    \n  \
    \n  :if ([:len \$mailAttachments] > 0 and [/tool e-mail get last-status] = \"succeeded\") do={\
    \n    :log info \"\$SMP File system cleanup.\"\
    \n    /file remove \$mailAttachments; \
    \n    :delay 2s;\
    \n  }\
    \n  \
    \n}\
    \n\
    \n\
    \n# Fire RouterOs update process\
    \nif (\$isOsNeedsToBeUpdated = true) do={\
    \n\
    \n  ## Set scheduled task to upgrade routerboard firmware on the next boot, task will be deleted when upgrade is done. (That is why you should keep original script name)\
    \n  /system schedule add name=BKPUPD-UPGRADE-ON-NEXT-BOOT on-event=\":delay 5s; /system scheduler remove BKPUPD-UPGRADE-ON-NEXT-BOOT; :global buGlobalVarUpdateStep 2; :delay 10s; /system script run Bac\
    kupAndUpdate;\" start-time=startup interval=0;\
    \n   \
    \n   :log info \"\$SMP everything is ready to install new RouterOS, going to reboot in a moment!\"\
    \n  ## command is reincarnation of the \"upgrade\" command - doing exactly the same but under a different name\
    \n  /system package update install;\
    \n}\
    \n\
    \n:log info \"\$SMP script \\\"Mikrotik RouterOS automatic backup & update\\\" completed its job.\";\
    \n"
;
