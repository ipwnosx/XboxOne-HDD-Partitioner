################################################################################
#
#  Author: XFiX
#  Date: 2019/10/22
#  Version: 8.1
#
#  Summary:
#  Create a true Xbox One 500GB, 1TB, or 2TB filesystem
#  This process is not a hack anymore
#  Past methods stretched a 500GB's filesystem
#  Now creates a resettable 500GB/1TB/2TB drive on ANY Xbox One OG/S/X Console
#  USE AT YOUR OWN RISK
#
#  Note 1: Run the following command within PowerShell to enable scripts:
#          Set-ExecutionPolicy RemoteSigned
#  Note 2: PowerShell 5.1 and Windows 10 is required since the Get-Disk,
#          Get-Partition, and Get-Volume cmdlets do not run on Windows 7
#
#  Change History:
#  2019/10/08 - PowerShell replacement and feature equivalent to
#               create_xbox_drive.bat 8.0 with improved multilingual support,
#               removed dependence on external executables, cleaner code
#               structure, improved logging, and drive size checks (8.1) - XFiX
#
#  Credit History:
#  2013/11 - Juvenal of Team Xecuter created the first working Python script
#  http://team-xecuter.com/forums/threads/141568-XBOX-ONE-How-To-Install-A-Bigger-Hard-Drive-%21
#
#  2014/07 - Ludvik Jerabek created the first bash script
#  http://www.ludvikjerabek.com/2014/07/14/xbox-one-fun-with-gpt-disk/
#
#  2016/06 - XFiX created a Windows batch script based on the bash script
#  https://www.youtube.com/playlist?list=PLURaLwRqr6g14Pl8qLO0E4ELBBCHfFh1V
#
#  2017/05 - A1DR1K discovered the secret behind what differentiates
#  500GB, 1TB, and 2TB Xbox One system hard drives
#  https://www.reddit.com/user/A1DR1K
#
################################################################################


### Handle useful PowerShell language references ###

# Running scripts is disabled on this system
# https://tecadmin.net/powershell-running-scripts-is-disabled-system/
# Approved Verbs for PowerShell Commands
# https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands
# About Comparison Operators
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_comparison_operators
# About Regular Expressions
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_regular_expressions
# Format a string expression
# https://ss64.com/ps/syntax-f-operator.html


### Handle command line paramerters if any ###

param(
    [parameter( ValueFromRemainingArguments = $true )]
    [string[]]$options # Leave all argument validation to the script, not to PowerShell
)


### Handle changeable script variables ###

# CHANGEME: 'Changeable drive letters'
# I've used higher letters to avoid conflicts
# A B C D E F G (H I J K L) M N O P Q R S T (U V W X Y) Z
# DUPlicatE letters
$TEMP_CONTENT_LDUPE    = "H"
$USER_CONTENT_LDUPE    = "I"
$SYSTEM_SUPPORT_LDUPE  = "J"
$SYSTEM_UPDATE_LDUPE   = "K"
$SYSTEM_UPDATE2_LDUPE  = "L"
# Xbox One letters
$TEMP_CONTENT_LETTER   = "U"
$USER_CONTENT_LETTER   = "V"
$SYSTEM_SUPPORT_LETTER = "W"
$SYSTEM_UPDATE_LETTER  = "X"
$SYSTEM_UPDATE2_LETTER = "Y"


### Handle unchangeable script variables ###

# Really useful function to hold error screens open
function Get-Pause {
    Write-Host -NoNewLine "Press any key to continue . . . "
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Write-Host
} # function Get-Pause

$XBO_VER         = "2019.10.22.8.1"

# As of 2019/10/22 Windows 10 = 5.1.18362.145, Windows 7 = 2.0 or 5.1.14409.1005 (KB3191566)
$PS_VERSION      = $PSVersionTable.PSVersion
$PS_VERSION_MIN  = [Version]'5.1'
$SCRIPT_TITLE = "Create Xbox One Drive $($XBO_VER) (PowerShell $($PS_VERSION))"
$host.ui.RawUI.WindowTitle = $SCRIPT_TITLE
if ($PS_VERSION_MIN -gt $PS_VERSION) {
    Write-Host
    Write-Host "Running:  PowerShell $PS_VERSION"
    Write-Host "Requires: PowerShell $PS_VERSION_MIN"
    Write-Host "Download Win7AndW2K8R2-KB3191566-x64.zip or Win7-KB3191566-x86.zip from here:"
    Write-Host "https://www.microsoft.com/en-us/download/details.aspx?id=54616"
    Write-Host
    Get-Pause
    Exit
}

# As of 2019/10/22 Windows 10 = 10.0.18362, Windows 7 = 6.1.7601
$WIN_VERSION     = [Version](Get-CimInstance Win32_OperatingSystem).Version
$WIN_VERSION_MIN = [Version]'10.0'
if ($WIN_VERSION_MIN -gt $WIN_VERSION) {
    Write-Host
    Write-Host "Running:  Windows $WIN_VERSION"
    Write-Host "Requires: Windows $WIN_VERSION_MIN"
    Write-Host "Get-Disk, Get-Partition, and Get-Volume cmdlets do not run on Windows 7"
    Write-Host "Windows 8 and 8.1 has not been tested"
    Write-Host
    Get-Pause
    Exit
}

#$SCRIPT_PATH  = split-path -parent $MyInvocation.MyCommand.Definition
$SCRIPT_NAME   = $MyInvocation.MyCommand.Name
$SCRIPT_PATH   = $PSScriptRoot

$TIMESTAMP     = Get-Date -UFormat "%Y.%m.%d %T"
$STOPWATCH     = [system.diagnostics.stopwatch]::startNew()
$XBO_LOG       = "$($Env:TEMP)\create_xbox_drive_cli.log"
$XBO_GD_SCRIPT = "$($Env:TEMP)\gds.txt"


# Common GUID values used by Xbox One
$DISK_GUID_2TB       = "5B114955-4A1C-45C4-86DC-D95070008139"
$DISK_GUID_1TB       = "25E8A1B2-0B2A-4474-93FA-35B847D97EE5"
$DISK_GUID_500GB     = "A2344BDB-D6DE-4766-9EB5-4109A12228E5"
$TEMP_CONTENT_GUID   = "B3727DA5-A3AC-4B3D-9FD6-2EA54441011B"
$USER_CONTENT_GUID   = "869BB5E0-3356-4BE6-85F7-29323A675CC7"
$SYSTEM_SUPPORT_GUID = "C90D7A47-CCB9-4CBA-8C66-0459F6B85724"
$SYSTEM_UPDATE_GUID  = "9A056AD7-32ED-4141-AEB1-AFB9BD5565DC"
$SYSTEM_UPDATE2_GUID = "24B2197C-9D01-45F9-A8E1-DBBCFA161EB2"

# Common Xbox One Partition Labels
$TEMP_CONTENT_LABEL   = "Temp Content"
$USER_CONTENT_LABEL   = "User Content"
$SYSTEM_SUPPORT_LABEL = "System Support"
$SYSTEM_UPDATE_LABEL  = "System Update"
$SYSTEM_UPDATE2_LABEL = "System Update 2"

# Common partition sizes used by Xbox One
# wmic partition get name,bootable,size,type
# Xbox temp partition size (41G)
$XBOX_TEMP_SIZE_IN_BYTES       = 44023414784
# Xbox user partition size max (1947GB)
$XBOX_USER_SIZE_IN_BYTES_MAX   = 2090575331328
# Xbox user partition size min (11GB)
$XBOX_USER_SIZE_IN_BYTES_MIN   = 11811160064
# Xbox user partition size (1662GB)
$XBOX_USER_SIZE_IN_BYTES_2TB   = 1784558911488
# Xbox user partition size (781GB)
$XBOX_USER_SIZE_IN_BYTES_1TB   = 838592364544
# Xbox user partition size (365GB)
$XBOX_USER_SIZE_IN_BYTES_500GB = 391915765760
# Xbox support partition size (40G)
$XBOX_SUPPORT_SIZE_IN_BYTES    = 42949672960
# Xbox update partition size (12G)
$XBOX_UPDATE_SIZE_IN_BYTES     = 12884901888
# Xbox update 2 partition size (7G)
$XBOX_UPDATE2_SIZE_IN_BYTES    = 7516192768

# Fake (DUPlicatE) GUIDs used to avoid drive conflicts on Windows (Offline signature collisions)
# These need to be changed before Xbox One installation
$DISK_GDUPE           = "C2D8931D-F53C-4057-B8C0-945B128D7866"
$TEMP_CONTENT_GDUPE   = "81002B01-E45E-4B55-A87B-6E3FC679856D"
$USER_CONTENT_GDUPE   = "3AF0ED71-7DAE-4105-9ABB-46D6A4F35751"
$SYSTEM_SUPPORT_GDUPE = "F9C3D4AF-0F6A-4878-A702-6AB67E599979"
$SYSTEM_UPDATE_GDUPE  = "E3833609-D4FC-4CF1-BCB6-7B8CDC46A44F"
$SYSTEM_UPDATE2_GDUPE = "7FCF2B0F-B6A0-42DA-9BF9-F3B26E70F2FC"

# x86 (32-bit) or Intel64 (64-bit)
$WINBIT = Get-ItemProperty -Path "HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0" -Name "Identifier" | Select-Object -ExpandProperty Identifier | ForEach-Object { $_.Split(" ")[0] }
$LANGID = Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Nls\Language" -Name "InstallLanguage" | Select-Object -ExpandProperty InstallLanguage
# Registry key isn't present on clean Windows 10 installs
#$LANGUI = Get-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "PreferredUILanguages" | Select-Object -ExpandProperty PreferredUILanguages
$LANGUI = (Get-Culture).Name

### Handle external executibles ###

if ($WINBIT -eq "x86") {
    $XBO_GDISK = "$($SCRIPT_PATH)\gdisk32"
} else {
    $XBO_GDISK = "$($SCRIPT_PATH)\gdisk64"
}
$XBO_ROBOCOPY = "$($Env:SystemRoot)\system32\robocopy"


### Handle embedded code ###


### Handle script functions ###

#
function Get-Header {
    cls
    # Clear/start the log file
    Write-Output "" | Tee-Object -FilePath $XBO_LOG | Write-Host
    Write-Output "**********************************************************************" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* $($SCRIPT_NAME):" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* This script creates a correctly formatted Xbox One HDD against the" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* drive YOU select." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* USE AT YOUR OWN RISK" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "*" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Created      2019.10.08.8.1" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Last Updated $($XBO_VER)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Now          $($TIMESTAMP)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* PowerShell   $($PS_VERSION)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Windows      $($WIN_VERSION)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* PWD          $($SCRIPT_PATH)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* System Type  $($WINBIT)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Language ID  $($LANGID)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Language UI  $($LANGUI)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "**********************************************************************" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
} # function Get-Header


#
function Test-Administrator {
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Output "* Administrative permissions confirmed                               *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    } else {
        Write-Output "* Current permissions inadequate. Please run this script using:      *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "* `"Run as administrator`"                                             *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Exit-Script
    }
} # function Test-Administrator


# Was :ChkForLetters rewritten from bat
function Confirm-DriveLetters {
    Write-Output "* Are required drive letters available? Checking...                  *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Confirm-DriveLetter $TEMP_CONTENT_LDUPE
    Confirm-DriveLetter $USER_CONTENT_LDUPE
    Confirm-DriveLetter $SYSTEM_SUPPORT_LDUPE
    Confirm-DriveLetter $SYSTEM_UPDATE_LDUPE
    Confirm-DriveLetter $SYSTEM_UPDATE2_LDUPE
    Confirm-DriveLetter $TEMP_CONTENT_LETTER
    Confirm-DriveLetter $USER_CONTENT_LETTER
    Confirm-DriveLetter $SYSTEM_SUPPORT_LETTER
    Confirm-DriveLetter $SYSTEM_UPDATE_LETTER
    Confirm-DriveLetter $SYSTEM_UPDATE2_LETTER
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* WARNING: Any non-free drive letters above may interfere with this  *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "*          script. Adjust the letters used in the 'Changeable drive  *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "*          letters' section near the top of this script.             *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "*          If you have an Xbox One drive attached non-free drive     *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "*          letters are expected.                                     *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
} # function Confirm-DriveLetters


# Was :ChkForLetter rewritten from bat
function Confirm-DriveLetter($letter) {
    $RESULT = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
    if ($RESULT.DriveLetter) {
        Write-Output "* Found $($letter): - $($RESULT.DriveType) Drive - $($RESULT.FileSystemLabel)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    } else {
        Write-Output "* $($letter): is free" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
} # function Confirm-DriveLetter($letter)


# Was :ChkForC rewritten from bat
function Test-ForC($disknum) {
    $RESULT = Get-Partition -DiskNumber $disknum -ErrorAction SilentlyContinue
    $IS_C = $FALSE
    foreach($PART in $RESULT) {
        if ($PART.DriveLetter -eq "C") {
            $IS_C = $TRUE
        }
    }
    return $IS_C
} # function Test-ForC($disknum)


#
function Select-MainMenu {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "Select Xbox One drive creation type:" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(a) Replace/Upgrade without a working original drive  (Standard Only)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(b) Replace/Upgrade keeping original drive data    (Standard and Non)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(c) Fix GUID values without formatting the drive   (Standard and Non)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(d) Backup `"System Update`" to current directory    (Standard and Non)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(e) Restore `"System Update`" from current directory (Standard and Non)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(f) Check all partitions for file system errors    (Standard and Non)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(g) Wipe drive of all partitions and GUID values   (Standard and Non)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(h) CANCEL" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host

    $XBO_CREATION_TYPE = Read-Host -Prompt '?'

    if ($XBO_CREATION_TYPE -notmatch "^[a-h]{1}$") {
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "`"$XBO_CREATION_TYPE`" is not valid please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Select-MainMenu
    }
    Write-Output "`"$XBO_CREATION_TYPE`" was selected" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    if ($XBO_CREATION_TYPE -eq "h") {
        Exit-DriveSelection
    }
    return $XBO_CREATION_TYPE
} # function Select-MainMenu


# Common disk cmdlets:
# Get-Disk, Get-Partition, Get-Volume, Set-Disk, Set-Partition, Set-Volume
# Get cmdlet object methods and properties:
# Get-Disk | Get-Member
# Get cmdlet usage information:
# Get-Help Get-Disk
# Get specific properties from cmdlet objects:
# Get-Disk -Number 0 | Select-Object -Property NumberOfPartitions
# Was :GetDisk rewritten from bat
function Select-DiskMenu($disktype, $diskskip) {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Scanning for connected USB/SATA drives . . .                       *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $disklist = New-Object System.Collections.ArrayList
    $disklist.Add("c") > $null
    $DISK_HEADER = "  {0,-5} {1,-8} {2,-8} {3}" -f "Disk", "Size", "Free", "Name"
    Write-Output $DISK_HEADER | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $RESULT = Get-Disk | Sort-Object -Property Number
    foreach($DISK in $RESULT) {
        if ($diskskip.Length -eq 0 -Or $DISK.Number -ne $diskskip) {
            $disklist.Add($DISK.Number) > $null
            $DISK_DISPLAY = "  {0,-5} {1,4} GB  {2,4} GB  {3}" -f "$($DISK.Number)", "$([string][math]::floor($DISK.Size/1024/1024/1024))", "$([string][math]::floor(($DISK.Size-$Disk.AllocatedSize)/1024/1024/1024))", "$($DISK.FriendlyName)"
            Write-Output $DISK_DISPLAY | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        }
    }
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Select $($disktype) Xbox One Drive . . .                                 *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "Enter c to CANCEL or use a Disk Number from the list above" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host

    $XBO_FORMAT_DRIVE = Read-Host -Prompt '?'

    Write-Output "`"$XBO_FORMAT_DRIVE`" was selected" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    if ($XBO_FORMAT_DRIVE -eq "c") {
        Exit-DriveSelection
    }
    if ($disklist -notcontains $XBO_FORMAT_DRIVE) {
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "`"$XBO_FORMAT_DRIVE`" is not valid, please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        $XBO_FORMAT_DRIVE = Select-DiskMenu $disktype $diskskip
    }
    if (Test-ForC $XBO_FORMAT_DRIVE) {
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "Found C: on selected disk `"$XBO_FORMAT_DRIVE`", please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        $XBO_FORMAT_DRIVE = Select-DiskMenu $disktype $diskskip
    }
    return $XBO_FORMAT_DRIVE
} # function Select-DiskMenu($disktype, $diskskip)


# Was :DskPrtLett rewritten from bat
# Rather than assume proper partition order 1-5 to assign drive letters
# Assign by matching the FileSystemLabel
function Set-PartitionLetters($disknum) {
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber

    # Remove all letters to prevent new partitions from holding ones we need
    foreach($PART in $RESULT) {
        Remove-PartitionAccessPath -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -Accesspath "$($PART.DriveLetter):" -ErrorAction SilentlyContinue
    } # foreach($PART in $RESULT)

    # Add all drive letters
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        switch ($VOLUME.FileSystemLabel) {
            "$($TEMP_CONTENT_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $TEMP_CONTENT_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($USER_CONTENT_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $USER_CONTENT_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($SYSTEM_SUPPORT_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_SUPPORT_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($SYSTEM_UPDATE_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($SYSTEM_UPDATE2_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE2_LETTER -ErrorAction SilentlyContinue
                break
            }

            # DUPlicatE letters
            "D$($TEMP_CONTENT_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $TEMP_CONTENT_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($USER_CONTENT_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $USER_CONTENT_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($SYSTEM_SUPPORT_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_SUPPORT_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($SYSTEM_UPDATE_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($SYSTEM_UPDATE2_LABEL)" {
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE2_LDUPE -ErrorAction SilentlyContinue
                break
            }
        }
    }
} # function Set-PartitionLetters($disknum)


# gdisk32 and gdisk64 used $XBO_DISK_SECTORS * $DEV_LOGICAL_BLOCK_SIZE_IN_BYTES
# to calculate device size in bytes, replaced with Get-DriveSizeBytes($disknum)
function Get-SectorCount($disknum) {
    # Get-Disk does not return disk sector count
} # function Get-SectorCount($disknum)


# gdisk32 and gdisk64 used $XBO_DISK_SECTORS * $DEV_LOGICAL_BLOCK_SIZE_IN_BYTES
# to calculate device size in bytes, replaced with Get-DriveSizeBytes($disknum)
function Get-BlockSize($disknum) {
    return Get-Disk -Number $disknum | Select-Object -ExpandProperty LogicalSectorSize
} # function Get-BlockSize($disknum)


#
function Get-DriveSizeBytes($disknum) {
    return Get-Disk -Number $disknum | Select-Object -ExpandProperty Size
} # function Get-DriveSizeBytes($disknum)


# Was :ListPart rewritten from bat
function Get-PartitionList($disknum) {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $PART_HEADER = "{0,-38} {1,-4} {2,-8} {3}" -f "GUID", "Dev", "Size", "Name"
    Write-Output $PART_HEADER | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $DISK_GUID = Get-Disk -Number $disknum | Select-Object -ExpandProperty Guid | ForEach-Object { $_.ToUpper() -replace '[{}]','' }
    switch ($DISK_GUID) {
        "$($DISK_GUID_500GB)" {
            $DISK_NAME = "(500GB)"
            break
        }
        "$($DISK_GUID_1TB)" {
            $DISK_NAME = "(1TB)"
            break
        }
        "$($DISK_GUID_2TB)" {
            $DISK_NAME = "(2TB)"
            break
        }
        "$($DISK_GDUPE)" {
            $DISK_NAME = "(DUPlicatE)"
            break
        }
        default {
            $DISK_NAME = "(Unknown)"
            break
        }
    }
    $DISK_DISPLAY = "{0,-38} {1,-4} {2,7}  {3}" -f "$($DISK_GUID)", "", "", "$($DISK_NAME)"
    Write-Output $DISK_DISPLAY | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $RESULT = Get-Partition -DiskNumber $disknum -ErrorAction SilentlyContinue | Sort-Object -Property PartitionNumber
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        $PART_GUID  = ""
        if ($PART.Guid) {
            $PART_GUID = $PART.Guid.ToUpper() -replace '[{}]',''
        }
        $PART_DEV  = ""
        if ($PART.DriveLetter) {
            $PART_DEV  = "$($PART.DriveLetter):"
        }
        $PART_SIZE = "$([string][math]::floor($PART.Size/1024/1024/1024)) GB"
        $PART_NAME = "'$($VOLUME.FileSystemLabel)'"
        $PART_DISPLAY = "{0,-38} {1,-4} {2,7}  {3}" -f "$($PART_GUID)", "$($PART_DEV)", "$($PART_SIZE)", "$($PART_NAME)"
        Write-Output $PART_DISPLAY | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
} # function Get-PartitionList($disknum)


#
function Select-WarningMsg($creationtype) {
    $nowarn = @("c","d","f")
    if ($nowarn -contains $creationtype) {
        return
    }
    $answers = @("y","n")
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Host -NoNewLine "WARNING: This will erase all data on this disk. Continue [Y,N]"
    $CONTINUE = Read-Host -Prompt '?'
    if ($answers -notcontains $CONTINUE) {
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "`"$CONTINUE`" is not valid, please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Select-WarningMsg $creationtype
    }
    if ($CONTINUE -eq "n") {
        Exit-DriveSelection
    }
} # function Select-WarningMsg($creationtype)


#
function Select-CopyMsg {
    $answers = @("y","n")
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Host -NoNewLine "WARNING: About to copy to the TARGET disk. Continue [Y,N]"
    $CONTINUE = Read-Host -Prompt '?'
    if ($answers -notcontains $CONTINUE) {
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "`"$CONTINUE`" is not valid, please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Select-CopyMsg
    }
    if ($CONTINUE -eq "n") {
        Exit-DriveCopy
    }
} # function Select-CopyMsg


#
function Get-FormattedMsg($creationtype, $disknum) {
    $nowarn = @("d", "f", "g")
    if ($nowarn -contains $creationtype) {
        return
    }
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Disk $disknum will be formatted as an Xbox One Drive . . .                *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
} # function Get-FormattedMsg($creationtype, $disknum)


# Was :MsgMexists and :MsgDexists rewritten from bat
function Get-DriveStatusMsg($letter, $label) {
    $RESULT = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
    if ($RESULT.DriveLetter) {
        Write-Output "* Found Drive $($letter): '$($label)'" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    } else {
        Write-Output "* Missing Drive $($letter): '$($label)'" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
} # function Get-DriveStatusMsg($letter, $label)


#
function Exit-DriveSelection {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Xbox One Drive Selection Cancelled                                 *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Exit-Script
} # function Exit-DriveSelection


#
function Exit-DriveCopy {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Xbox One Drive Copy Cancelled                                      *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Exit-Script
} # function Exit-DriveCopy


#
function Exit-Script {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Script execution complete." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $TIMESTAMP = Get-Date -UFormat "%Y.%m.%d %T"
    Write-Output "* Ended: $($TIMESTAMP)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Script ran for $([math]::floor($STOPWATCH.Elapsed.TotalSeconds)) seconds" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Get-Pause
    Exit
} # function Exit-Script


#
function Test-Letters($type) {
    $ALL_OK = $TRUE
    if ($type -eq "a") {
        # Backup-RoboCopy or Restore-RoboCopy
        # "(a) `"System Update`" only (more important)"
        $letters = @("$($SYSTEM_UPDATE_LETTER)")
        $labels  = @("$($SYSTEM_UPDATE_LABEL)")
    } elseif ($type -eq "b") {
        # Backup-RoboCopy or Restore-RoboCopy
        # "(b) `"All Partitions`"     (less important)"
        $letters = @("$($TEMP_CONTENT_LETTER)",
                     "$($USER_CONTENT_LETTER)",
                     "$($SYSTEM_SUPPORT_LETTER)",
                     "$($SYSTEM_UPDATE_LETTER)",
                     "$($SYSTEM_UPDATE2_LETTER)")
        $labels  = @("$($TEMP_CONTENT_LABEL)",
                     "$($USER_CONTENT_LABEL)",
                     "$($SYSTEM_SUPPORT_LABEL)",
                     "$($SYSTEM_UPDATE_LABEL)",
                     "$($SYSTEM_UPDATE2_LABEL)")
    } else {
        # Backup-DirectCopy
        $letters = @("$($TEMP_CONTENT_LETTER)",   "$($TEMP_CONTENT_LDUPE)",
                     "$($USER_CONTENT_LETTER)",   "$($USER_CONTENT_LDUPE)",
                     "$($SYSTEM_SUPPORT_LETTER)", "$($SYSTEM_SUPPORT_LDUPE)",
                     "$($SYSTEM_UPDATE_LETTER)",  "$($SYSTEM_UPDATE_LDUPE)",
                     "$($SYSTEM_UPDATE2_LETTER)", "$($SYSTEM_UPDATE2_LDUPE)")
        $labels  = @("$($TEMP_CONTENT_LABEL)",    "D$($TEMP_CONTENT_LABEL)",
                     "$($USER_CONTENT_LABEL)",    "D$($USER_CONTENT_LABEL)",
                     "$($SYSTEM_SUPPORT_LABEL)",  "D$($SYSTEM_SUPPORT_LABEL)",
                     "$($SYSTEM_UPDATE_LABEL)",   "D$($SYSTEM_UPDATE_LABEL)",
                     "$($SYSTEM_UPDATE2_LABEL)",  "D$($SYSTEM_UPDATE2_LABEL)")
    }
    For ($i=0; $i -lt $letters.Length; $i++) {
        $RESULT = Get-Volume -DriveLetter $letters[$i] -ErrorAction SilentlyContinue
        if (-Not ($RESULT.DriveLetter)) {
            Write-Output "* Missing '$($labels[$i])' $($letters[$i]):" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            $ALL_OK = $FALSE
        }
    }
    return $ALL_OK
} # function Test-Letters($type)


# Was :RoboCopyAll rewritten from bat
function Backup-DirectCopy {
    if (Test-Letters) {
        Invoke-RoboCopy "DirectCopy" "Temp_Content"    "$($TEMP_CONTENT_LETTER):"   "$($TEMP_CONTENT_LDUPE):"
        Invoke-RoboCopy "DirectCopy" "User_Content"    "$($USER_CONTENT_LETTER):"   "$($USER_CONTENT_LDUPE):"
        Invoke-RoboCopy "DirectCopy" "System_Support"  "$($SYSTEM_SUPPORT_LETTER):" "$($SYSTEM_SUPPORT_LDUPE):"
        Invoke-RoboCopy "DirectCopy" "System_Update"   "$($SYSTEM_UPDATE_LETTER):"  "$($SYSTEM_UPDATE_LDUPE):"
        Invoke-RoboCopy "DirectCopy" "System_Update_2" "$($SYSTEM_UPDATE2_LETTER):" "$($SYSTEM_UPDATE2_LDUPE):"
    } else {
        Write-Output "* Something is missing, cannot copy data" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
} # function Backup-DirectCopy


# Was :RoboCopyRun <sourceVarName> <targetVarName> <lognameVarValue> rewritten from bat
function Invoke-RoboCopy($type, $logname, $source, $target) {
    if (-Not (Test-Path -Path "$($target)")) {
        $null = New-Item -Path "$($target)" -ItemType "directory" -Force
    }
    if (Test-Path -Path "$($target)") {
        $XBO_ROBOCOPY_LOG = "$($Env:TEMP)\RoboCopy-$($logname).log"
        $XBO_RUN = "`"$($XBO_ROBOCOPY)`" `"$($source)`" `"$($target)`" /XD `"`$RECYCLE.BIN`" `"System Volume Information`" /ZB /MIR /XJ /R:3 /W:3 /TS /FP /ETA /LOG:`"$($XBO_ROBOCOPY_LOG)`" /TEE"
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "* Running $($type): $($XBO_RUN)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        cmd /c "$($XBO_RUN)" 2>&1

        if ($type -eq "Backup") {
            # Unhide top level $target directory by removing the 'Hidden,System' Attributes
            Clear-ItemProperty -Path "$($target)" -Name Attributes
        }
    } else {
        Write-Output "* Target $($target) is missing, skipping . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
} # function Invoke-RoboCopy($type, $logname, $source, $target)


# Was :RoboPartSel rewritten from bat
function Select-RoboCopyPartition($robotype) {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "Select partition $($robotype) type:" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(a) `"System Update`" only (more important)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(b) `"All Partitions`"     (less important)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(c) CANCEL" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host

    $XBO_BACKUP_TYPE = Read-Host -Prompt '?'
    if ($XBO_BACKUP_TYPE -notmatch "^[a-c]{1}$") {
        Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "`"$XBO_BACKUP_TYPE`" is not valid please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Select-RoboCopyPartition $robotype
    }
    if ($XBO_BACKUP_TYPE -eq "c") {
        Exit-DriveSelection
    }
    return $XBO_BACKUP_TYPE
} # function Select-RoboCopyPartition($robotype)


# Was :RoboBackUpd rewritten from bat
function Backup-RoboCopy {
    $XBO_BACKUP_TYPE = Select-RoboCopyPartition "Backup"
    if (Test-Letters $XBO_BACKUP_TYPE) {
        if ($XBO_BACKUP_TYPE -eq "a") {
            Invoke-RoboCopy "Backup" "System_Update"   "$($SYSTEM_UPDATE_LETTER):"  "$($SCRIPT_PATH)\System_Update"
        } else {
            Invoke-RoboCopy "Backup" "Temp_Content"    "$($TEMP_CONTENT_LETTER):"   "$($SCRIPT_PATH)\Temp_Content"
            Invoke-RoboCopy "Backup" "User_Content"    "$($USER_CONTENT_LETTER):"   "$($SCRIPT_PATH)\User_Content"
            Invoke-RoboCopy "Backup" "System_Support"  "$($SYSTEM_SUPPORT_LETTER):" "$($SCRIPT_PATH)\System_Support"
            Invoke-RoboCopy "Backup" "System_Update"   "$($SYSTEM_UPDATE_LETTER):"  "$($SCRIPT_PATH)\System_Update"
            Invoke-RoboCopy "Backup" "System_Update_2" "$($SYSTEM_UPDATE2_LETTER):" "$($SCRIPT_PATH)\System_Update_2"
        }
    } else {
        Write-Output "* Something is missing, cannot copy data" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
} # function Backup-RoboCopy


# Was :RoboRestUpd rewritten from bat
function Restore-RoboCopy {
    $XBO_BACKUP_TYPE = Select-RoboCopyPartition "Restore"
    if (Test-Letters $XBO_BACKUP_TYPE) {
        if ($XBO_BACKUP_TYPE -eq "a") {
            Invoke-RoboCopy "Restore" "System_Update"   "$($SCRIPT_PATH)\System_Update"   "$($SYSTEM_UPDATE_LETTER):"
        } else {
            Invoke-RoboCopy "Restore" "Temp_Content"    "$($SCRIPT_PATH)\Temp_Content"    "$($TEMP_CONTENT_LETTER):"
            Invoke-RoboCopy "Restore" "User_Content"    "$($SCRIPT_PATH)\User_Content"    "$($USER_CONTENT_LETTER):"
            Invoke-RoboCopy "Restore" "System_Support"  "$($SCRIPT_PATH)\System_Support"  "$($SYSTEM_SUPPORT_LETTER):"
            Invoke-RoboCopy "Restore" "System_Update"   "$($SCRIPT_PATH)\System_Update"   "$($SYSTEM_UPDATE_LETTER):"
            Invoke-RoboCopy "Restore" "System_Update_2" "$($SCRIPT_PATH)\System_Update_2" "$($SYSTEM_UPDATE2_LETTER):"
        }
    } else {
        Write-Output "* Something is missing, cannot copy data" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
} # function Restore-RoboCopy


# Was :ChkDskAll rewritten from bat
function Repair-Partitions($disknum) {
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        $PART_GUID  = ""
        if ($PART.Guid) {
            $PART_GUID = $PART.Guid.ToUpper() -replace '[{}]',''
        }
        $PART_DEV  = ""
        if ($PART.DriveLetter) {
            $PART_DEV  = "$($PART.DriveLetter):"
        }
        $PART_SIZE = "$([string][math]::floor($PART.Size/1024/1024/1024)) GB"
        $PART_NAME = "'$($VOLUME.FileSystemLabel)'"
        $PART_DISPLAY = "{0,-9} {1,-3} {2,7}  {3,-18} {4}" -f "Checking", "$($PART_DEV)", "$($PART_SIZE)", "$($PART_NAME)", ". . .  "
        Write-Host -NoNewLine $PART_DISPLAY
        Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Repair-Volume -OfflineScanAndFix
    }
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
} # function Repair-Partitions($disknum)


# Was :GdWipe rewritten from bat
# Destructive: As the name implies, cleans a disk by removing all partition information and un-initializing it
#              then initializes the disk as GPT
function Clear-TargetDisk($disknum) {
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Removing existing partitions with Clear-Disk . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    # Force the disk online due to possible signature collisions
    Set-Disk -Number $disknum -IsOffline $FALSE
    # -ErrorAction SilentlyContinue
    Clear-Disk -Number $disknum -RemoveData -RemoveOEM -Confirm:$FALSE
    # Creates a small Reserved partition which needs to be removed
    Initialize-Disk -Number $disknum -PartitionStyle GPT -Confirm:$FALSE -ErrorAction SilentlyContinue
    Remove-Partition -DiskNumber $disknum -PartitionNumber 1 -Confirm:$FALSE -ErrorAction SilentlyContinue
} # function Clear-TargetDisk($disknum)


#
function Test-DriveTooSmall($disksize, $disknum) {
    $size500gb = @("a")
    $size1tb   = @("b")
    $size2tb   = @("c")
    $sizeauto  = @("d", "e", "f")
    $XBOX_DRIVE_SIZE_IN_BYTES = Get-DriveSizeBytes($disknum)
    # Standard sizes are 500GB, 1TB, or 2TB minimum
    if ($size2tb -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_2TB + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Write-Output "* Xbox One Drive TARGET Too Small for 2TB Standard Minimum           *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            return $TRUE
        }
    } elseif ($size1tb -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_1TB + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Write-Output "* Xbox One Drive TARGET Too Small for 1TB Standard Minimum           *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            return $TRUE
        }
    } elseif ($size500gb -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_500GB + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Write-Output "* Xbox One Drive TARGET Too Small for 500GB Standard Minimum         *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            return $TRUE
        }
    }
    # Non-Standard sizes are 120GB minimum
    if ($sizeauto -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_MIN + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Write-Output "* Xbox One Drive TARGET Too Small 120GB Non-Standard Minimum         *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            return $TRUE
        }
    }
    return $FALSE
} # function Test-DriveTooSmall($disksize, $disknum)


# Was :GdStruct rewritten from bat
function Select-DiskLayout($creationtype) {
    $standard = @("a")
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "Select partition layout:" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(a) 500GB Standard (365GB)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(b) 1TB Standard   (781GB)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "(c) 2TB Standard  (1662GB)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    if ($standard -contains $creationtype) {
        Write-Output "(d) CANCEL" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    } else {
        Write-Output "(d) Autosize Non-Standard w/ 500GB Disk GUID (11GB MIN 1947GB MAX)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "(e) Autosize Non-Standard w/ 1TB Disk GUID   (11GB MIN 1947GB MAX)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "(f) Autosize Non-Standard w/ 2TB Disk GUID   (11GB MIN 1947GB MAX)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
        Write-Output "(g) CANCEL" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    }
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $XBO_SIZE = Read-Host -Prompt '?'

    if ($standard -contains $creationtype) {
        if ($XBO_SIZE -notmatch "^[a-d]{1}$") {
            Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Write-Output "`"$XBO_SIZE`" is not valid please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Select-DiskLayout $creationtype
        }
        if ($XBO_SIZE -eq "d") {
            Exit-DriveSelection
        }
    } else {
        if ($XBO_SIZE -notmatch "^[a-g]{1}$") {
            Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Write-Output "`"$XBO_SIZE`" is not valid please try again" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            Select-DiskLayout $creationtype
        }
        if ($XBO_SIZE -eq "g") {
            Exit-DriveSelection
        }
    }
    return $XBO_SIZE
} # function Select-DiskLayout($creationtype)


# Was :GdGuid rewritten from bat
# Set disk and partition GUID values, no direct way to do this using PowerShell/diskpart?
# Does:    Sets GUID values of the disk and partitions in proper 1-5 order
# Doesn't: Create partitions, format as NTFS, set FileSystemLabel, or drive letters
function Invoke-GdiskGuid($creationtype, $disksize, $disknum) {
    #($guiddisk, $guidpart1, $guidpart2, $guidpart3, $guidpart4, $guidpart5)
    $xboxone   = @("a", "c")
    $duplicate = @("b")

    $guid500gb = @("a", "d")
    $guid1tb   = @("b", "e")
    $guid2tb   = @("c", "f")

    if ($xboxone -contains $creationtype) {
        if ($guid2tb -contains $disksize) {
            $guiddisk = $DISK_GUID_2TB
        } elseif ($guid1tb -contains $disksize) {
            $guiddisk = $DISK_GUID_1TB
        } elseif ($guid500gb -contains $disksize) {
            $guiddisk = $DISK_GUID_500GB
        }
        $guidpart1 = $TEMP_CONTENT_GUID
        $guidpart2 = $USER_CONTENT_GUID
        $guidpart3 = $SYSTEM_SUPPORT_GUID
        $guidpart4 = $SYSTEM_UPDATE_GUID
        $guidpart5 = $SYSTEM_UPDATE2_GUID
    } elseif ($duplicate -contains $creationtype) {
        $guiddisk  = $DISK_GDUPE
        $guidpart1 = $TEMP_CONTENT_GDUPE
        $guidpart2 = $USER_CONTENT_GDUPE
        $guidpart3 = $SYSTEM_SUPPORT_GDUPE
        $guidpart4 = $SYSTEM_UPDATE_GDUPE
        $guidpart5 = $SYSTEM_UPDATE2_GDUPE
    }

    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Changing disk and partition GUID values with $($XBO_GDISK) . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host

    Set-Content -Path "$($XBO_GD_SCRIPT)" -Value "x"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "g"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "$($guiddisk)"

    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "c"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "1"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "$($guidpart1)"

    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "c"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "2"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "$($guidpart2)"

    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "c"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "3"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "$($guidpart3)"

    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "c"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "4"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "$($guidpart4)"

    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "c"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "5"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "$($guidpart5)"

    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "w"
    Add-Content -Path "$($XBO_GD_SCRIPT)" -Value "y"

    # Add quotes to handles spaces in path prior to cmd /c
    $XBO_RUN = "`"$($XBO_GDISK)`" \\.\physicaldrive$($disknum) < `"$($XBO_GD_SCRIPT)`""
    cmd /c "$($XBO_RUN)" 2>&1 | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
} # function Invoke-GdiskGuid($creationtype, $disksize, $disknum)


# Destructive: Formats the partition and sets the volume label
# Does:    Formats as NTFS and sets the FileSystemLabel based on partition GUID values
# Doesn't: Create partitions, set GUID values, or drive letters
function Format-VolumeLabel($disknum) {
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        switch ($PART.Guid.ToUpper() -replace '[{}]','') {
            "$($TEMP_CONTENT_GUID)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) '$($TEMP_CONTENT_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($TEMP_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($USER_CONTENT_GUID)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) '$($USER_CONTENT_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($USER_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_SUPPORT_GUID)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) '$($SYSTEM_SUPPORT_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SYSTEM_SUPPORT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE_GUID)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) '$($SYSTEM_UPDATE_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SYSTEM_UPDATE_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE2_GUID)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) '$($SYSTEM_UPDATE2_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SYSTEM_UPDATE2_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }

            # DUPlicatE letters
            "$($TEMP_CONTENT_GDUPE)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($TEMP_CONTENT_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($TEMP_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($USER_CONTENT_GDUPE)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($USER_CONTENT_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($USER_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_SUPPORT_GDUPE)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($SYSTEM_SUPPORT_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($SYSTEM_SUPPORT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE_GDUPE)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($SYSTEM_UPDATE_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($SYSTEM_UPDATE_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE2_GDUPE)" {
                Write-Output "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($SYSTEM_UPDATE2_LABEL)' . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($SYSTEM_UPDATE2_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
        }
    }
} # function Format-VolumeLabel($disknum)


# Was :LabelVol rewritten from bat
# Non-destructive: Sets the volume label
# Rather than assume proper partition order 1-5 to assign the FileSystemLabel
# Assign by matching the GUID
# Does:    Set the FileSystemLabel based on partition GUID values
# Doesn't: Create partitions, format as NTFS, set GUID values, or drive letters
function Set-VolumeLabel($disknum) {
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        switch ($PART.Guid.ToUpper() -replace '[{}]','') {
            "$($TEMP_CONTENT_GUID)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "$($TEMP_CONTENT_LABEL)"
                break
            }
            "$($USER_CONTENT_GUID)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "$($USER_CONTENT_LABEL)"
                break
            }
            "$($SYSTEM_SUPPORT_GUID)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "$($SYSTEM_SUPPORT_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE_GUID)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "$($SYSTEM_UPDATE_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE2_GUID)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "$($SYSTEM_UPDATE2_LABEL)"
                break
            }

            # DUPlicatE letters
            "$($TEMP_CONTENT_GDUPE)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($TEMP_CONTENT_LABEL)"
                break
            }
            "$($USER_CONTENT_GDUPE)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($USER_CONTENT_LABEL)"
                break
            }
            "$($SYSTEM_SUPPORT_GDUPE)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($SYSTEM_SUPPORT_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE_GDUPE)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($SYSTEM_UPDATE_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE2_GDUPE)" {
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($SYSTEM_UPDATE2_LABEL)"
                break
            }
        }
    }
} # function Set-VolumeLabel($disknum)


# Was :GdPart rewritten from bat
# Does:    Creates properly sized Xbox One partitions in proper 1-5 order
# Doesn't: Format as NTFS, set FileSystemLabel, set GUID values, or drive letters
function New-Partitions($disksize, $disknum) {
    # Determine the only variable partition size $XBOX_USER_SIZE_IN_BYTES
    $size500gb = @("a")
    $size1tb   = @("b")
    $size2tb   = @("c")
    $sizeauto  = @("d", "e", "f")

    if ($size2tb -contains $disksize) {
        $XBOX_USER_SIZE_IN_BYTES  = $XBOX_USER_SIZE_IN_BYTES_2TB
    } elseif ($size1tb -contains $disksize) {
        $XBOX_USER_SIZE_IN_BYTES  = $XBOX_USER_SIZE_IN_BYTES_1TB
    } elseif ($size500gb -contains $disksize) {
        $XBOX_USER_SIZE_IN_BYTES  = $XBOX_USER_SIZE_IN_BYTES_500GB
    } elseif ($sizeauto -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES = Get-DriveSizeBytes($disknum)
        # Align data to the nearest GB
        $XBOX_USER_SIZE_IN_BYTES  = ([math]::floor(($XBOX_DRIVE_SIZE_IN_BYTES - $XBOX_TEMP_SIZE_IN_BYTES - $XBOX_SUPPORT_SIZE_IN_BYTES - $XBOX_UPDATE_SIZE_IN_BYTES - $XBOX_UPDATE2_SIZE_IN_BYTES)/1024/1024/1024))*1024*1024*1024
        if ($XBOX_USER_SIZE_IN_BYTES -gt $XBOX_USER_SIZE_IN_BYTES_MAX) {
            Write-Output "* Disk larger than 2TB, Limiting User Content to 1.9TB               *" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
            $XBOX_USER_SIZE_IN_BYTES = $XBOX_USER_SIZE_IN_BYTES_MAX
        }
    }

    Write-Output "* Creating partition 1 with $($XBOX_TEMP_SIZE_IN_BYTES) bytes . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    New-Partition -DiskNumber $disknum -Size $XBOX_TEMP_SIZE_IN_BYTES | Out-Null

    Write-Output "* Creating partition 2 with $($XBOX_USER_SIZE_IN_BYTES) bytes . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    New-Partition -DiskNumber $disknum -Size $XBOX_USER_SIZE_IN_BYTES | Out-Null

    Write-Output "* Creating partition 3 with $($XBOX_SUPPORT_SIZE_IN_BYTES) bytes . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    New-Partition -DiskNumber $disknum -Size $XBOX_SUPPORT_SIZE_IN_BYTES | Out-Null

    Write-Output "* Creating partition 4 with $($XBOX_UPDATE_SIZE_IN_BYTES) bytes . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    New-Partition -DiskNumber $disknum -Size $XBOX_UPDATE_SIZE_IN_BYTES | Out-Null

    Write-Output "* Creating partition 5 with $($XBOX_UPDATE2_SIZE_IN_BYTES) bytes . . ." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    New-Partition -DiskNumber $disknum -Size $XBOX_UPDATE2_SIZE_IN_BYTES | Out-Null
} # function New-Partitions($disksize, $disknum)


# Was :GdName rewritten from bat
# Change partition's name for Linux sgdisk compatibility with gdisk


#
function Start-PSAdmin {Start-Process PowerShell -Verb RunAs}


### Handle script processing and output ###

Get-Header

Test-Administrator

Confirm-DriveLetters

Get-Pause

$XBO_CREATION_TYPE = Select-MainMenu

$XBO_SOURCE_DRIVE = ''
if ($XBO_CREATION_TYPE -eq "b") {
    $XBO_SOURCE_DRIVE = Select-DiskMenu "SOURCE"
    Set-PartitionLetters $XBO_SOURCE_DRIVE
}

$XBO_TARGET_DRIVE = Select-DiskMenu "TARGET" $XBO_SOURCE_DRIVE

Get-PartitionList $XBO_TARGET_DRIVE
Select-WarningMsg $XBO_CREATION_TYPE
Get-FormattedMsg $XBO_CREATION_TYPE $XBO_TARGET_DRIVE

# Split out to the various Xbox One drive creation types
switch ($XBO_CREATION_TYPE) {
    "a" {
        $XBO_SIZE = Select-DiskLayout $XBO_CREATION_TYPE
        if (Test-DriveTooSmall $XBO_SIZE $XBO_TARGET_DRIVE) {
            Exit-Script
        }
        Clear-TargetDisk $XBO_TARGET_DRIVE
        New-Partitions $XBO_SIZE $XBO_TARGET_DRIVE
        Invoke-GdiskGuid $XBO_CREATION_TYPE $XBO_SIZE $XBO_TARGET_DRIVE
        Format-VolumeLabel $XBO_TARGET_DRIVE
        Set-PartitionLetters $XBO_TARGET_DRIVE
        break
    }
    "b" {
        $XBO_SIZE = Select-DiskLayout $XBO_CREATION_TYPE
        if (Test-DriveTooSmall $XBO_SIZE $XBO_TARGET_DRIVE) {
            Exit-Script
        }
        Clear-TargetDisk $XBO_TARGET_DRIVE
        New-Partitions $XBO_SIZE $XBO_TARGET_DRIVE
        Invoke-GdiskGuid $XBO_CREATION_TYPE $XBO_SIZE $XBO_TARGET_DRIVE
        Format-VolumeLabel $XBO_TARGET_DRIVE
        Set-PartitionLetters $XBO_TARGET_DRIVE
        Select-CopyMsg
        Backup-DirectCopy
        break
    }
    "c" {
        $XBO_SIZE = Select-DiskLayout $XBO_CREATION_TYPE
        Invoke-GdiskGuid $XBO_CREATION_TYPE $XBO_SIZE $XBO_TARGET_DRIVE
        Set-VolumeLabel $XBO_TARGET_DRIVE
        Set-PartitionLetters $XBO_TARGET_DRIVE
        break
    }
    "d" {
        Set-PartitionLetters $XBO_TARGET_DRIVE
        Backup-RoboCopy
        break
    }
    "e" {
        Set-PartitionLetters $XBO_TARGET_DRIVE
        Restore-RoboCopy
        break
    }
    "f" {
        Repair-Partitions $XBO_TARGET_DRIVE
        break
    }
    "g" {
        Clear-TargetDisk $XBO_TARGET_DRIVE
        break
    }
}

Get-PartitionList $XBO_TARGET_DRIVE
Get-DriveStatusMsg $SYSTEM_UPDATE_LETTER $SYSTEM_UPDATE_LABEL
Exit-Script
