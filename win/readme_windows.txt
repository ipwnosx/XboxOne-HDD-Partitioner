Last Updated: 2019/10/23
Author: XFiX
https://gbatemp.net/threads/xbox-one-internal-hard-drive-upgrade-or-repair-build-any-size-drive-that-works-on-any-console.496212/
https://www.youtube.com/playlist?list=PLURaLwRqr6g14Pl8qLO0E4ELBBCHfFh1V

Creates a properly partitioned Xbox One hard drive. You'll want to source the
entire original drive files or use the latest OSU1 files.

FEATURES:
1. Create a Standard Xbox One 500GB, 1TB, or 2TB internal hard drive
2. Upgrade a Standard Xbox One drive to non-standard sizes including
   as small as 138GB, as large as 1947GB, and other non-standard sizes
3. Set Standard Xbox One GUID values without formatting the drive
4. Backup "System Update" to current directory System_Update and more
5. Restore "System Update" from current directory System_Update and more
6. Check all partitions for file system errors using chkdsk
7. Wipe drive of all partitions and GUID values

This script is a direct replacement to create_xbox_drive.sh for Linux:
create_xbox_drive_old.bat is tested and works on Windows 7 and 10
create_xbox_drive.bat and create_xbox_drive_gui.bat are tested and only work
on Windows 10

You'll need some sort of USB to SATA device or have the ability to connect a
SATA drive directly to your PC. I recommend the USB3S2SAT3CB USB 3.0 to SATA
adapter cable.


NOTES AND WARNINGS:
NOTE 1: Xbox One internal drives have a 2TB limit that you cannot get around.
        This is a bug or feature by Microsoft's design.
        This is the video I made trying to fill a 5TB internal drive.
        https://www.youtube.com/watch?v=tcoa8Xx_6oU
        Version 7.0 and above max the "User Content" partition out at 1947GB.
        Theoretically you can created a larger partition than this but you
        cannot use the additional space.

NOTE 2: You need to run this script from an Administrator Command Prompt
        using the "Run as administrator" feature.

NOTE 3: For this script to work on non-English Windows systems
        C:\Windows\System32\en-US needs to be present.
        Control Panel\All Control Panel Items\Language\Add languages
        English (United States)

NOTE 4: Click "Cancel" or "X" on any "You need to format the disk in drive ?:
        before you can use it." messages.

NOTE 5: diskmgmt.msc is your friend. Keep it open while running this script
        to check progress and verify proper partitioning and formatting.

WARNING 1: E100 is bad. It is possible to do an offline update to resolve it
           but this mostly isn't the case. E100 is the only know error that
           actually refers to the Blu-ray drive. Under certain circumstances
           during an Xbox One update the Blu-ray drive firmware can become
           permanently corrupted. Any sort of Blu-ray drive failure involving
           the daughterboard will brick your system since only the original
           factory matching Xbox One motherboard and Blu-ray daughterboard can
           be used together.
           YOU CANNOT REPLACE A BLU-RAY DAUGHTERBOARD FROM ANOTHER SYSTEM!

WARNING 2: Only have one Xbox One or future Xbox One drive connected when
           running this script to ensure the right drive gets formatted and
           avoid Offline signature collisions!

           This means disconnecting the SOURCE drive after:
           (b) Replace/Upgrade keeping original drive data
           but before:
           (c) Fix GUID values without formatting the drive
           When redoing the entire process run this step on the TARGET with
           the SOURCE disconnected:
           (g) Wipe drive of all partitions and GUID values

WARNING 3: Always use "Safely Remove Hardware and Eject Media" and "Eject" the
           newly created drive.
           If you receive the message: "Windows can't stop your
           'Generic volume' device because a program is still using it."
           Either shutdown your system and remove the drive or use
           diskmgmt.msc right click the disk, select "Offline", then "Online"
           and then "Safely Remove Hardware and Eject Media" and "Eject".

SCRIPT FUNCTIONS EXPLAINED:
(a) Replace/Upgrade without a working original drive  (Standard Only) - used to fix systems when the original drive has failed
(b) Replace/Upgrade keeping original drive data    (Standard and Non) - used to swap to a smaller or larger standard or non-standard drive
(c) Fix GUID values without formatting the drive   (Standard and Non) - should be used after step (b) and after disconnecting the SOURCE drive
(d) Backup "System Update" to current directory    (Standard and Non) - use before doing a Reset or Upgrade, better safe than sorry
(e) Restore "System Update" from current directory (Standard and Non) - use after doing a Reset or Upgrade, told you so
(f) Check all partitions for file system errors    (Standard and Non) - optionally check for filesystem corruption or prepare for Clonezilla
(g) Wipe drive of all partitions and GUID values   (Standard and Non) - used to blank a drive before rerunning step (b)
(h) CANCEL                                                            - skip making any drive modifications

PARTITION LAYOUT:
There are 5 partitions on an Xbox One drive. The 2nd partition 'User Content'
is what this selection refers to. The other 4 partitions are always the same
size regardless of the drive size.

All partitions are rounded to the nearest gibibyte (normally and not to be
confused with gigabyte). So options (d) through (g) will mostly do the right
thing. Options (a) through (c) are for wanting to force a particular size on
the target drive.

Most people should choose (a), (b), or (c). If you have a 256GB or 750GB you
should select (d). For 3TB, 4TB, or 5TB drives you should select (f).

(a) 500GB Standard (365GB)    (779MB Unallocated)
(b) 1TB Standard   (781GB)  (50.51GB Unallocated)
(c) 2TB Standard  (1662GB) (101.02GB Unallocated)
(d) Autosize Non-Standard w/ 500GB Disk GUID (1947GB MAX) - create an autosized 'User Content' resetting to 500GB
(e) Autosize Non-Standard w/ 1TB Disk GUID   (1947GB MAX) - create an autosized 'User Content' resetting to 1TB
(f) Autosize Non-Standard w/ 2TB Disk GUID   (1947GB MAX) - create an autosized 'User Content' resetting to 2TB


REPAIR AND UPGRADE PATHS:
Xbox One Internal Hard Drive Backup and Restore Upgrade
https://www.youtube.com/watch?v=Yq9CQdyOzac
Menu roadmap:
(d) Backup "System Update" to current directory    (Standard and Non)
(a) Replace/Upgrade without a working original drive  (Standard Only)
(e) Restore "System Update" from current directory (Standard and Non)


Xbox One Internal Hard Drive Direct Copy Upgrade
https://www.youtube.com/watch?v=xBvGFUaOGB4
Menu roadmap:
(b) Replace/Upgrade keeping original drive data    (Standard and Non)
(c) Fix GUID values without formatting the drive   (Standard and Non)


Xbox One Internal Hard Drive Repair or Replace Using
https://www.youtube.com/watch?v=4xYQQicXdU0
Menu roadmap:
(a) Replace/Upgrade without a working original drive  (Standard Only)


EXAMPLE SCRIPT USAGE AND OUTPUT:
 1. Unzip xboxonehdd-master-8.1.zip to the Desktop which will create an xboxonehdd-master directory
 2. Open an Administrator Command Prompt:
    Windows 7: Click "Start Menu -> All Programs -> Accessories" right click "Command Prompt" select "Run as administrator"
    Windows 10 1607 and earlier: Right click "Start Menu" select "Command Prompt (Admin)"
    Windows 10 1703 and later: Right click "Start Menu" select "Windows PowerShell (Admin)"
 3. In the Command Prompt paste:
    Command Prompt:
    cd %USERPROFILE%\Desktop\xboxonehdd-master\win
    Windows PowerShell:
    cd $Env:USERPROFILE\Desktop\xboxonehdd-master\win
 4. Then paste:
    .\create_xbox_drive.bat
 5. Follow all the prompts and be sure to select the appropriate drive. Example below:

    **********************************************************************
    * create_xbox_drive.ps1:
    * This script creates a correctly formatted Xbox One HDD against the
    * drive YOU select.
    * USE AT YOUR OWN RISK
    *
    * Created      2019.10.08.8.1
    * Last Updated 2019.10.22.8.1
    * Now          2019.10.23 21:50:28
    * PowerShell   5.1.18362.145
    * Windows      10.0.18362
    * PWD          C:\Users\mpdavig\Desktop\xboxonehdd-master\win
    * System Type  Intel64
    * Language ID  0409
    * Language UI  en-US
    **********************************************************************

    * Administrative permissions confirmed                               *

    * Are required drive letters available? Checking...                  *
    * H: is free
    * I: is free
    * J: is free
    * K: is free
    * L: is free
    * Found U: - Fixed Drive - Temp Content
    * Found V: - Fixed Drive - User Content
    * Found W: - Fixed Drive - System Support
    * Found X: - Fixed Drive - System Update
    * Found Y: - Fixed Drive - System Update 2

    * WARNING: Any non-free drive letters above may interfere with this  *
    *          script. Adjust the letters used in the 'Changeable drive  *
    *          letters' section near the top of this script.             *
    *          If you have an Xbox One drive attached non-free drive     *
    *          letters are expected.                                     *

    Press any key to continue . . .

    Select Xbox One drive creation type:
    (a) Replace/Upgrade without a working original drive  (Standard Only)
    (b) Replace/Upgrade keeping original drive data    (Standard and Non)
    (c) Fix GUID values without formatting the drive   (Standard and Non)
    (d) Backup "System Update" to current directory    (Standard and Non)
    (e) Restore "System Update" from current directory (Standard and Non)
    (f) Check all partitions for file system errors    (Standard and Non)
    (g) Wipe drive of all partitions and GUID values   (Standard and Non)
    (h) CANCEL

    ?: a
    "a" was selected

    * Scanning for connected USB/SATA drives . . .                       *
      Disk  Size     Free     Name
      1     3726 GB     0 GB  WDC WD40EZRX-00SPEB0
      2     3726 GB     0 GB  WDC WD40EZRX-00SPEB0
      3     1863 GB   101 GB  ASMT 2115

    * Select TARGET Xbox One Drive . . .                                 *
    Enter c to CANCEL or use a Disk Number from the list above
    ?: 3
    "3" was selected

    GUID                                   Dev  Size     Name
    5B114955-4A1C-45C4-86DC-D95070008139                 (2TB)
    B3727DA5-A3AC-4B3D-9FD6-2EA54441011B   U:     41 GB  'Temp Content'
    869BB5E0-3356-4BE6-85F7-29323A675CC7   V:   1662 GB  'User Content'
    C90D7A47-CCB9-4CBA-8C66-0459F6B85724   W:     40 GB  'System Support'
    9A056AD7-32ED-4141-AEB1-AFB9BD5565DC   X:     12 GB  'System Update'
    24B2197C-9D01-45F9-A8E1-DBBCFA161EB2   Y:      7 GB  'System Update 2'


    WARNING: This will erase all data on this disk. Continue [Y,N]?: y

    * Disk 3 will be formatted as an Xbox One Drive . . .                *

    Select partition layout:
    (a) 500GB Standard (365GB)
    (b) 1TB Standard   (781GB)
    (c) 2TB Standard  (1662GB)
    (d) CANCEL

    ?: c
    * Removing existing partitions with Clear-Disk . . .                 *

    GUID                                   Dev  Size     Name
    A2A1044F-42EF-4279-B915-377EA82A63C3                 (Unknown)

    * Creating partition 1 with 44023414784 bytes . . .
    * Creating partition 2 with 1784558911488 bytes . . .
    * Creating partition 3 with 42949672960 bytes . . .
    * Creating partition 4 with 12884901888 bytes . . .
    * Creating partition 5 with 7516192768 bytes . . .

    * Changing disk and partition GUID values with C:\Users\mpdavig\Desktop\xboxonehdd-master\win\gdisk64 . . .

    * Formatting and labeling partition 'Temp Content' . . .
    * Formatting and labeling partition 'User Content' . . .
    * Formatting and labeling partition 'System Support' . . .
    * Formatting and labeling partition 'System Update' . . .
    * Formatting and labeling partition 'System Update 2' . . .

    GUID                                   Dev  Size     Name
    5B114955-4A1C-45C4-86DC-D95070008139                 (2TB)
    B3727DA5-A3AC-4B3D-9FD6-2EA54441011B   U:     41 GB  'Temp Content'
    869BB5E0-3356-4BE6-85F7-29323A675CC7   V:   1662 GB  'User Content'
    C90D7A47-CCB9-4CBA-8C66-0459F6B85724   W:     40 GB  'System Support'
    9A056AD7-32ED-4141-AEB1-AFB9BD5565DC   X:     12 GB  'System Update'
    24B2197C-9D01-45F9-A8E1-DBBCFA161EB2   Y:      7 GB  'System Update 2'

    * Found Drive X: 'System Update'

    * Script execution complete.
    * Ended: 2019.10.23 21:51:50
    * Script ran for 81 seconds

    Press any key to continue . . .


 6. The last bit of output should look like the following, except for the
    first line depending on the drive size, if not run the script again:
    A2344BDB-D6DE-4766-9EB5-4109A12228E5             (500GB)
    25E8A1B2-0B2A-4474-93FA-35B847D97EE5             (1TB)

    GUID                                 Dev Size    Name
    5B114955-4A1C-45C4-86DC-D95070008139             (2TB)
    B3727DA5-A3AC-4B3D-9FD6-2EA54441011B U:    41 GB 'Temp Content'
    869BB5E0-3356-4BE6-85F7-29323A675CC7 V:   365 GB 'User Content'
    C90D7A47-CCB9-4CBA-8C66-0459F6B85724 W:    40 GB 'System Support'
    9A056AD7-32ED-4141-AEB1-AFB9BD5565DC X:    12 GB 'System Update'
    24B2197C-9D01-45F9-A8E1-DBBCFA161EB2 Y:  7168 MB 'System Update 2'

 7. To view the log file paste this:
    Command Prompt:
    notepad %TEMP%\create_xbox_drive.log
    notepad %TEMP%\create_xbox_drive_cli.log
    notepad %TEMP%\create_xbox_drive_gui.log
    notepad %TEMP%\RoboCopy-Temp_Content.log
    notepad %TEMP%\RoboCopy-User_Content.log
    notepad %TEMP%\RoboCopy-System_Support.log
    notepad %TEMP%\RoboCopy-System_Update.log
    notepad %TEMP%\RoboCopy-System_Update_2.log
    Windows PowerShell:
    notepad $Env:TEMP\create_xbox_drive.log
    notepad $Env:TEMP\create_xbox_drive_cli.log
    notepad $Env:TEMP\create_xbox_drive_gui.log
    notepad $Env:TEMP\RoboCopy-Temp_Content.log
    notepad $Env:TEMP\RoboCopy-User_Content.log
    notepad $Env:TEMP\RoboCopy-System_Support.log
    notepad $Env:TEMP\RoboCopy-System_Update.log
    notepad $Env:TEMP\RoboCopy-System_Update_2.log

 8. OPTIONAL (skip if OSU1 doesn't match the last successful update):
    Download the latest OSU1.zip which contains the files:

    $SystemUpdate/host.xvd
    $SystemUpdate/SettingsTemplate.xvd
    $SystemUpdate/system.xvd
    $SystemUpdate/systemaux.xvd
    $SystemUpdate/systemmisc.xvd
    $SystemUpdate/systemtools.xvd
    $SystemUpdate/updater.xvd

    Place them in the 'System Update' partition as:

    A/host.xvd
    A/SettingsTemplate.xvd
    A/system.xvd
    A/systemaux.xvd
    A/systemmisc.xvd
    A/systemtools.xvd
    B/host.xvd
    B/SettingsTemplate.xvd
    B/system.xvd
    B/systemaux.xvd
    B/systemmisc.xvd
    B/systemtools.xvd
    updater.xvd
