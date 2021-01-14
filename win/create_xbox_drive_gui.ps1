################################################################################
#
#  Author: XFiX
#  Date: 2019/11/22
#  Version: 9.0
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
#  2019/10/24 - Added GUI form support (9.0) - XFiX
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

# Building Forms with PowerShell - Part 1 (The Form)
# https://blogs.technet.microsoft.com/stephap/2012/04/23/building-forms-with-powershell-part-1-the-form/
# How to Create a GUI for PowerShell Scripts?
# https://theitbros.com/powershell-gui-for-scripts/
# Online editor to create GUI forms for PowerShell scripts:
# https://poshgui.com/Editor
# Send parameters to button.add_click function created dynamically
# https://social.technet.microsoft.com/Forums/scriptcenter/en-US/c471f12f-8567-44fa-857e-ae32dffb806c/send-parameters-to-buttonaddclick-function-created-dynamically?forum=winserverpowershell
# Adds a Microsoft .NET Core class to a PowerShell session
# https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.utility/add-type?view=powershell-6
# Written by Rob van der Woude
# http://www.robvanderwoude.com
# Which Disk is that volume on?
# http://gcd.w3.uvm.edu/2013/01/which-disk-is-that-volume-on/
# Creating a Balloon Tip Notification in PowerShell
# https://www.sapien.com/blog/2007/04/27/creating-a-balloon-tip-notification-in-powershell/
# Code to extract icons from Shell32.dll by Thomas Levesque:
# http://stackoverflow.com/questions/6873026
# Code to hide and restore console by Anthony:"
# http://stackoverflow.com/a/15079092


### TODO:
# 1. Functionize everything
# 2. Build a menu for each step
# 3. Tie it all together


### Handle command line paramerters if any ###

param(
    [parameter( ValueFromRemainingArguments = $TRUE )]
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
# CLI Hide = 0, Show = 1
$XBO_SHOW_CLI = 0


### Handle unchangeable script variables ###

# Really useful function to hold error screens open
function Get-Pause {
    Write-Host -NoNewLine "Press any key to continue . . . "
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    Write-Host
} # function Get-Pause

$XBO_VER         = "2019.11.22.9.0"

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
$XBO_LOG       = "$($Env:TEMP)\create_xbox_drive_gui.log"
$XBO_GD_SCRIPT = "$($Env:TEMP)\gds.txt"
$XBO_X         = 4
$XBO_Y         = 20


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


### Handle ScriptBlocks and Globals ###
[hashtable]$global:XBO_DIALOG = [ordered]@{}
$global:XBO_DIALOG.form   = $null
$global:XBO_CREATION_TEXT = ""
$XBO_CREATION_TYPE = { $global:XBO_CREATION_TYPE = $this.Text -replace '[&]','' }
$XBO_FORMAT_DRIVE  = { $global:XBO_FORMAT_DRIVE  = $this.Text -replace '[&]','' }
$XBO_YES_NO        = { $global:XBO_YES_NO        = $this.Text -replace '[&]','' }
$XBO_SIZE          = { $global:XBO_SIZE          = $this.Text -replace '[&]','' }
$XBO_BACKUP_TYPE   = { $global:XBO_BACKUP_TYPE   = $this.Text -replace '[&]','' }


### Handle Assembly code ###
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")

### Handle embedded code ###

### Hide console window                 ###
### by Anthony on StackOverflow.com     ###
### http://stackoverflow.com/a/15079092 ###
### Very slick but may not be needed?   ###
# C# code assigned to $signature# requires real tabs and curly braces on it's own lines
$signature1 = @'
public static void ShowConsoleWindow( int state )
{
	var handle = GetConsoleWindow( );
	ShowWindow( handle, state );
}

[System.Runtime.InteropServices.DllImport( "kernel32.dll" )]
static extern IntPtr GetConsoleWindow( );

[System.Runtime.InteropServices.DllImport( "user32.dll" )]
static extern bool ShowWindow( IntPtr hWnd, int nCmdShow );
'@


### Extract system tray icon from Shell32.dll                    ###
### C# code to extract icons from Shell32.dll by Thomas Levesque ###
### http://stackoverflow.com/questions/6873026                   ###
# C# code assigned to $signature# requires real tabs and curly braces on it's own lines
$signature2 = @'
[DllImport( "Shell32.dll", EntryPoint = "ExtractIconExW", CharSet = CharSet.Unicode, ExactSpelling = true, CallingConvention = CallingConvention.StdCall )]
private static extern int ExtractIconEx( string sFile, int iIndex, out IntPtr piLargeVersion, out IntPtr piSmallVersion, int amountIcons );

public static Icon Extract( string file, int number, bool largeIcon )
{
	IntPtr large;
	IntPtr small;
	ExtractIconEx( file, number, out large, out small, 1 );
	try
	{
		return Icon.FromHandle( largeIcon ? large : small );
	}
	catch
	{
		return null;
	}
}
'@


### Handle creating forms and form elements ###

# aka Horizontal
function Get-TextXaxis($text) {
    # Determine the next x starting point
    $chars = $text | Measure-Object -Character | Select-Object -ExpandProperty Characters
    $x = $chars * 1
    return $x
} # function Get-TextXaxis($text)


# aka Vertical
function Get-TextYaxis($text) {
    # Determine the next y starting point
    $lines = $text | Measure-Object -Line | Select-Object -ExpandProperty Lines
    $y = $lines * 14
    return $y
} # function Get-TextYaxis($text)


# Form Button
function Get-FormButton($text, $x, $y, $size) {
    # Account for labels after buttons -NoNewLine
    Write-Output "($($text)) " | Tee-Object -FilePath $XBO_LOG -Append | Write-Host -NoNewLine # Log all form output
    $width = 40
    if ($size) {
        $width = $size
    }
    $Button           = New-Object System.Windows.Forms.Button
    $Button.TabIndex  = $y
    $Button.ForeColor = 'Black'
    $Button.BackColor = 'ButtonFace'
    $Button.Text      = "$($text)"
    #$Button.AutoSize  = $TRUE
    $Button.Size      = "$($width),18"
    #$Button.Width     = 60
    #$Button.Height    = 24
    $Button.Location  = New-Object System.Drawing.Point($x,$y)
    #$Button.Font      = 'Microsoft Sans Serif,10'
    return $Button
} # function Get-FormButton($text, $x, $y, $size)


# Form Label
function Get-FormLabel($text, $x, $y, $color) {
    Write-Output "$($text)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host -NoNewLine # Log all form output
    $textcolor = 'White'
    if ($color) {
        $textcolor = $color
    }
    $Label           = New-Object System.Windows.Forms.Label
    $Label.ForeColor = $textcolor
    $Label.BackColor = 'DarkGreen'
    $Label.Text      = "$($text)"
    $Label.AutoSize  = $TRUE
    #$Label.Size      = '35,20'
    #$Label.Width     = 35
    #$Label.Height    = 20
    $Label.Location  = New-Object System.Drawing.Point($x,$y)
    #$Label.Font      = 'Microsoft Sans Serif,10'
    return $Label
} # function Get-FormLabel($text, $x, $y, $color)


# Handle a larger dialog for form input
function Show-SystemDialog($elements) {
    ### Create a dialog window ###
    # This breaks progress bars, progress doesn't update until the second iteration
    # enable rich visual styles in PowerShell console mode:
    #[System.Windows.Forms.Application]::EnableVisualStyles( )

    $XBO_FORM = New-Object System.Windows.Forms.Form
    # Need to split the screen to handle 1366x768 displays
    $XBO_FORM.Width           = 880
    $XBO_FORM.Height          = 680
    #$XBO_FORM.AutoSize        = $TRUE
    #$XBO_FORM.AutoSizeMode    = "GrowAndShrink"

    #$XBO_FORM.Font            = 'Courier New, 10'
    $XBO_FORM.Font            = 'Consolas,9.25'
    $XBO_FORM.ForeColor       = 'White'
    $XBO_FORM.BackColor       = 'DarkGreen'
    $XBO_FORM.MaximizeBox     = $FALSE;
    $XBO_FORM.FormBorderStyle = 'FixedSingle'
    $XBO_FORM.StartPosition   = 'CenterScreen'
    $XBO_FORM.Text            = $SCRIPT_TITLE

    # SuspendLayout() prevents further button presses
    $XBO_FORM.SuspendLayout()
    # Required for reusing the same form but cannot reuse ShowDialog()
    # So we now use Hide() but left this in
    $XBO_FORM.Controls.Clear()
    foreach($key in $elements.Keys) {
	$XBO_FORM.Controls.Add($elements[$key])
        # All buttons close the form so that we can build the next
	if ($($elements[$key].GetType() | Select-Object -ExpandProperty Name) -eq "Button") {
	    $XBO_FORM.AcceptButton = $elements[$key] # Pressing Enter  closes the dialog
	    $XBO_FORM.CancelButton = $elements[$key] # Pressing Escape closes the dialog
	}
    }
    $XBO_FORM.ResumeLayout()
    if ($XBO_FORM.Visible -eq $FALSE) {
        # Calling ShowDialog() waits for a response
        [void] $XBO_FORM.ShowDialog()
    }
    $XBO_FORM.Hide()
    $XBO_FORM.Close()
} # function Show-SystemDialog($elements)


# Handle a smaller dialog purely for progress
function Open-ProgressDialog($msg) {
    ### Create a dialog window ###
    # This breaks progress bars, progress doesn't update until the second iteration
    # enable rich visual styles in PowerShell console mode:
    #[System.Windows.Forms.Application]::EnableVisualStyles( )

    $Dialog = New-Object System.Windows.Forms.Form
    # Need to split the screen to handle 1366x768 displays
    $Dialog.Width           = 880
    $Dialog.Height          = 150
    #$Dialog.AutoSize        = $TRUE
    #$Dialog.AutoSizeMode    = "GrowAndShrink"
    # Progress-Bar suggestion
    #$Dialog.Width           = 500
    #$Dialog.Height          = 100

    #$Dialog.Font            = 'Courier New, 10'
    $Dialog.Font            = 'Consolas,9.25'
    $Dialog.ForeColor       = 'White'
    $Dialog.BackColor       = 'DarkGreen'
    $Dialog.MaximizeBox     = $FALSE;
    $Dialog.FormBorderStyle = 'FixedSingle'
    $Dialog.StartPosition   = 'CenterScreen'
    $Dialog.Text            = $SCRIPT_TITLE

    # SuspendLayout() prevents further button presses
    $Dialog.SuspendLayout()
    # Required for reusing the same form but cannot reuse ShowDialog()
    # So we now use Hide() but left this in
    $Dialog.Controls.Clear()

    $Dialog.ResumeLayout()

    $LabelA = New-Object System.Windows.Forms.Label
    $LabelA.ForeColor = 'PaleTurquoise'
    $LabelA.Text = "$($global:XBO_CREATION_TEXT)"
    $LabelA.Left = $XBO_X
    $y = $XBO_X
    $LabelA.Top = $y
    #$LabelA.AutoSize  = $TRUE
    $LabelA.Width = 880 - 20
    $LabelA.Height = 15
    #$LabelA.Font = "Tahoma"
    $Dialog.Controls.Add($LabelA)

    $LabelB = New-Object System.Windows.Forms.Label
    $output = "$($msg)"
    Write-Output "$($output)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host -NoNewLine # Log all form output
    $LabelB.Text = $output
    $LabelB.Left = $XBO_X
    $y = $y + $XBO_Y + $XBO_Y
    $LabelB.Top = $y
    #$LabelB.AutoSize  = $TRUE
    $LabelB.Width = 880 - 20
    $LabelB.Height = 15
    #$LabelB.Font = "Tahoma"
    $Dialog.Controls.Add($LabelB)

    $ProgressBar = New-Object System.Windows.Forms.ProgressBar
    $ProgressBar.Name = "PowerShellProgressBar"
    $ProgressBar.Value = 0
    #$ProgressBar.Style="Blocks"
    $ProgressBar.Style="Continuous"

    $System_Drawing_Size = New-Object System.Drawing.Size
    $System_Drawing_Size.Width = 880 - 40
    $System_Drawing_Size.Height = 20
    $ProgressBar.Size = $System_Drawing_Size
    #$ProgressBar.AutoSize  = $TRUE
    $ProgressBar.Left = $XBO_X
    $y = $y + $XBO_Y
    $ProgressBar.Top = $y
    $ProgressBar.Minimum = 0
    $ProgressBar.Maximum = 100
    $Dialog.Controls.Add($ProgressBar)

    if ($Dialog.Visible -eq $FALSE) {
        # Calling ShowDialog() waits for a response
        #[void] $Dialog.ShowDialog()
        # Using Show() doesn't wait for a response
        [void] $Dialog.Show()
    }
    [void] $Dialog.Focus()

    $Dialog.Refresh()
    Start-Sleep -Seconds 1
    $global:XBO_DIALOG.form        = $Dialog
    $global:XBO_DIALOG.label       = $LabelB
    $global:XBO_DIALOG.progressbar = $ProgressBar
} # function Open-ProgressDialog($msg)


#
function Close-ProgressDialog {
    if ($global:XBO_DIALOG.form -ne $null) {
        $global:XBO_DIALOG.form.Hide()
        $global:XBO_DIALOG.form.Close()
    }
} # function Close-ProgressDialog


#
function Write-ProgressDialog($msg, $cnt, $total) {
    if ($global:XBO_DIALOG.form -ne $null) {
        # Calculate The Percentage Completed
        [Int]$Percentage = ($cnt/$total)*100
        $global:XBO_DIALOG.progressbar.Value = $Percentage

        # Host output is handled by Get-FormLabel()
        #Write-Output "$($msg)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host -NoNewLine # Log all form output
        $global:XBO_DIALOG.label.Text = $msg
        $global:XBO_DIALOG.form.Refresh()
        Start-Sleep -Milliseconds 450
    }
    return $msg
} # function Write-ProgressDialog($msg, $cnt, $total)


# Replace Invoke-RoboCopy() with Get-ChildItem, New-Item and Copy-Item
function Copy-ProgressDialog($type, $logname, $source, $target) {
    Open-ProgressDialog "Starting $type From: $source To: $target`n"

    #$FSItems = Get-ChildItem -Path $source -File -Recurse -Force | Select Name, @{Name="Path";Expression={$_.FullName}}
    $FSItems = Get-ChildItem -Path $source -Recurse -Force -ErrorAction SilentlyContinue `
        | Where-Object {$_.FullName -NotLike "*`$RECYCLE.BIN*" -And $_.FullName -NotLike "*System Volume Information*"} `
        | Select-Object Name, Length, @{Name="Path";Expression={$_.FullName}}, @{Name="Relative";Expression={$_.FullName -replace [Regex]::Escape("$($source)"),""}}, @{Name="IsDir";Expression={$_.PSIsContainer}}
    $Counter = 0
    $Fail    = 0
    $Pass    = 0

    ForEach ($Item In $FSItems) {
	# Calculate The Percentage Completed
	$Counter++
        [Int]$Percentage = ($Counter/$FSItems.Count)*100
        $global:XBO_DIALOG.progressbar.Value = $Percentage

        $target_full = "$($target)$($Item.Relative)"
        if ($Item.IsDir) {
            if (-Not (Test-Path -Path "$($target_full)" -ErrorAction SilentlyContinue)) {
                $null = New-Item -Path "$($target_full)" -ItemType "directory" -Force -ErrorAction SilentlyContinue
                if ($?) {
                    $Pass++
                    $output = "$($type) Directory Creation [PASSED] ($($Counter)/$($FSItems.Count)) $($target_full)`n"
                } else {
                    $Fail++
                    $output = "$($type) Directory Creation [FAILED] ($($Counter)/$($FSItems.Count)) $($target_full)`n"
                }
            } else {
                $Pass++
                $output = "$($type) Directory Creation [EXISTS] ($($Counter)/$($FSItems.Count)) $($target_full)`n"
            }
        } else {
            if ((-Not (Test-Path -Path "$($target_full)" -ErrorAction SilentlyContinue)) -Or (Get-Item $target_full).Length -ne $Item.Length) {
                Copy-Item -Path "$($Item.Path)" -Destination "$($target_full)" -Force -ErrorAction SilentlyContinue
                if ($?) {
                    $Pass++
                    $output = "$($type) File Creation [PASSED] ($($Counter)/$($FSItems.Count)) $($target_full)`n"
                } else {
                    $Fail++
                    $output = "$($type) File Creation [FAILED] ($($Counter)/$($FSItems.Count)) $($target_full)`n"
                }
            } else {
                $Pass++
                $output = "$($type) File Creation [EXISTS] ($($Counter)/$($FSItems.Count)) $($target_full)`n"
            }
        }

        Write-Output "$($output)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host -NoNewLine # Log all form output
        $global:XBO_DIALOG.label.Text = $output
	$global:XBO_DIALOG.form.Refresh()
	Start-Sleep -Milliseconds 150
    }
    $output = "Completed Copy From: $source To: $target, Total: $($Counter) Pass: $($Pass) Fail: $($Fail)`n"
    Write-Output "$($output)`n" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host -NoNewLine # Log all form output
    $global:XBO_DIALOG.label.Text = $output
    $global:XBO_DIALOG.form.Refresh()
    Start-Sleep -Seconds 1

    Close-ProgressDialog
    return $output
} # function Copy-ProgressDialog($type, $logname, $source, $target)


### Handle script functions ###

#
function Get-Header {
    cls
    $header = @"

**********************************************************************
* $($SCRIPT_NAME):
* This script creates a correctly formatted Xbox One HDD against the
* drive YOU select.
* USE AT YOUR OWN RISK
*
* Created      2019.10.08.8.1
* Last Updated $($XBO_VER)
* Now          $($TIMESTAMP)
* PowerShell   $($PS_VERSION)
* Windows      $($WIN_VERSION)
* PWD          $($SCRIPT_PATH)
* System Type  $($WINBIT)
* Language ID  $($LANGID)
* Language UI  $($LANGUI)
**********************************************************************

"@
    return $header
} # function Get-Header


#
function Test-Administrator {
    [hashtable]$return = [ordered]@{}
    if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        $output  = "* Administrative permissions confirmed                               *`n"
	$exit    = $FALSE
    } else {
        $output  = "* Current permissions inadequate. Please run this script using:      *`n"
        $output += "* `"Run as administrator`"                                             *`n"
	$exit    = $TRUE
    }
    $return.output = $output
    $return.exit   = $exit
    return $return
} # function Test-Administrator


# Was :ChkForLetters rewritten from bat
function Confirm-DriveLetters {
    $output  = "* Are required drive letters available? Checking...                  *`n"
    $output += Confirm-DriveLetter $TEMP_CONTENT_LDUPE
    $output += Confirm-DriveLetter $USER_CONTENT_LDUPE
    $output += Confirm-DriveLetter $SYSTEM_SUPPORT_LDUPE
    $output += Confirm-DriveLetter $SYSTEM_UPDATE_LDUPE
    $output += Confirm-DriveLetter $SYSTEM_UPDATE2_LDUPE
    $output += Confirm-DriveLetter $TEMP_CONTENT_LETTER
    $output += Confirm-DriveLetter $USER_CONTENT_LETTER
    $output += Confirm-DriveLetter $SYSTEM_SUPPORT_LETTER
    $output += Confirm-DriveLetter $SYSTEM_UPDATE_LETTER
    $output += Confirm-DriveLetter $SYSTEM_UPDATE2_LETTER
    $output += "`n"
    $output += "* WARNING: Any non-free drive letters above may interfere with this  *`n"
    $output += "*          script. Adjust the letters used in the 'Changeable drive  *`n"
    $output += "*          letters' section near the top of this script.             *`n"
    $output += "*          If you have an Xbox One drive attached non-free drive     *`n"
    $output += "*          letters are expected.                                     *`n"
    $output += "`n"
    return $output
} # function Confirm-DriveLetters


# Was :ChkForLetter rewritten from bat
function Confirm-DriveLetter($letter) {
    $RESULT = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
    if ($RESULT.DriveLetter) {
        $output  = "* Found $($letter): - $($RESULT.DriveType) Drive - $($RESULT.FileSystemLabel)`n"
    } else {
        $output  = "* $($letter): is free`n"
    }
    return $output
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
function Get-IntroForm {
    [hashtable]$elements = [ordered]@{}

    # Clear/start the log file
    Write-Output "" | Tee-Object -FilePath $XBO_LOG | Write-Host -NoNewLine
    $header = Get-Header

    # Hide console
    $hideconsole::ShowConsoleWindow( $XBO_SHOW_CLI )

    $admin = Test-Administrator
    if (($admin.exit)) {
        Exit-ScriptForm "$($header)`n$($admin.output)"
        return
    }

    $driveletters = Confirm-DriveLetters

    $y = $XBO_X
    $formheader = "$($header)`n$($admin.output)`n$($driveletters)"
    $elements.Label0 = Get-FormLabel $formheader $XBO_X $y
    $y = $(Get-TextYaxis $formheader)

    $y = $y + 30
    $elements.Button1 = Get-FormButton "&Next" $XBO_X $y 80

    Show-SystemDialog $elements

    Select-MainMenuForm
} # function Get-IntroForm


# Should be re-written from create_xbox_drive.ps1 - Select-MainMenu
# to Select-MainMenuForm to handle a form interface instead of pure text
function Select-MainMenuForm {
    [hashtable]$elements = [ordered]@{}

    $y = $XBO_X
    $formheader = "`nSelect Xbox One drive creation type:`n"
    $elements.Label0 = Get-FormLabel $formheader $XBO_X $y
    $y = $(Get-TextYaxis $formheader)

    $y = $y + $XBO_Y
    $elements.Button1 = Get-FormButton "&a" $XBO_X $y
    $elements.Button1.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button1.Add_Click({Select-MainMenuHandler "a"})
    $elements.Label1  = Get-FormLabel "Replace/Upgrade without a working original drive  (Standard Only)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button2 = Get-FormButton "&b" $XBO_X $y
    $elements.Button2.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button2.Add_Click({Select-MainMenuHandler "b"})
    $elements.Label2  = Get-FormLabel "Replace/Upgrade keeping original drive data    (Standard and Non)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button3 = Get-FormButton "&c" $XBO_X $y
    $elements.Button3.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button3.Add_Click({Select-MainMenuHandler "c"})
    $elements.Label3  = Get-FormLabel "Fix GUID values without formatting the drive   (Standard and Non)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button4 = Get-FormButton "&d" $XBO_X $y
    $elements.Button4.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button4.Add_Click({Select-MainMenuHandler "d"})
    $elements.Label4  = Get-FormLabel "Backup `"System Update`" to current directory    (Standard and Non)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button5 = Get-FormButton "&e" $XBO_X $y
    $elements.Button5.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button5.Add_Click({Select-MainMenuHandler "e"})
    $elements.Label5  = Get-FormLabel "Restore `"System Update`" from current directory (Standard and Non)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button6 = Get-FormButton "&f" $XBO_X $y
    $elements.Button6.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button6.Add_Click({Select-MainMenuHandler "f"})
    $elements.Label6  = Get-FormLabel "Check all partitions for file system errors    (Standard and Non)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button7 = Get-FormButton "&g" $XBO_X $y
    $elements.Button7.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button7.Add_Click({Select-MainMenuHandler "g"})
    $elements.Label7  = Get-FormLabel "Wipe drive of all partitions and GUID values   (Standard and Non)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button8 = Get-FormButton "&h" $XBO_X $y
    $elements.Button8.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button8.Add_Click({Select-MainMenuHandler "h"})
    $elements.Label8  = Get-FormLabel "DirectCopy without formatting the target drive (Standard and Non)`n" 45 ($y+3)

    $y = $y + 30
    $elements.Button9 = Get-FormButton "ca&Ncel" $XBO_X $y 80
    $elements.Button9.Add_Click($XBO_CREATION_TYPE)
    #$elements.Button9.Add_Click({Exit-DriveSelection})

    $y = $y + $XBO_Y
    $elements.Label9 = Get-FormLabel "`n" $XBO_X $y

    Show-SystemDialog $elements

    if ($global:XBO_CREATION_TYPE -eq "caNcel") {
        Exit-DriveSelection
    } else {
        Select-MainMenuHandler $global:XBO_CREATION_TYPE
    }

    <#
    $output += "(a) Replace/Upgrade without a working original drive  (Standard Only)`n"
    $output += "(b) Replace/Upgrade keeping original drive data    (Standard and Non)`n"
    $output += "(c) Fix GUID values without formatting the drive   (Standard and Non)`n"
    $output += "(d) Backup `"System Update`" to current directory    (Standard and Non)`n"
    $output += "(e) Restore `"System Update`" from current directory (Standard and Non)`n"
    $output += "(f) Check all partitions for file system errors    (Standard and Non)`n"
    $output += "(g) Wipe drive of all partitions and GUID values   (Standard and Non)`n"
    $output += "(h) caNcel`n"
    #>

} # function Select-MainMenuForm


# Common disk cmdlets:
# Get-Disk, Get-Partition, Get-Volume, Set-Disk, Set-Partition, Set-Volume
# Get cmdlet object methods and properties:
# Get-Disk | Get-Member
# Get cmdlet usage information:
# Get-Help Get-Disk
# Get specific properties from cmdlet objects:
# Get-Disk -Number 0 | Select-Object -Property NumberOfPartitions
# Was :GetDisk rewritten from bat
function Select-DiskMenuForm($msg, $disktype, $diskskip) {
    [hashtable]$elements = [ordered]@{}
    # Reset $XBO_FORMAT_DRIVE from prior calls
    $XBO_FORMAT_DRIVE  = { $global:XBO_FORMAT_DRIVE  = $this.Text -replace '[&]','' }
    $output  = "`n* Scanning for connected USB/SATA drives . . .                       *`n"
    $DISK_HEADER = "  {0,-6} {1,-8} {2,-8} {3}" -f "Disk", "Size", "Free", "Name"
    $output += "$($DISK_HEADER)`n"

    $y = $XBO_X
    $formheader = "$($global:XBO_CREATION_TEXT)"
    $elements.LabelA = Get-FormLabel $formheader $XBO_X $y 'PaleTurquoise'
    $y = $(Get-TextYaxis $formheader)

    $formheader = "$($output)"
    $elements.LabelB = Get-FormLabel $formheader $XBO_X $y
    $y = $y + $(Get-TextYaxis $formheader)

    $RESULT = Get-Disk | Sort-Object -Property Number
    foreach($DISK in $RESULT) {
        if ($diskskip.Length -eq 0 -Or $DISK.Number -ne $diskskip) {
            $DISK_DISPLAY = "   {0,4} GB  {1,4} GB  {2}" -f "$([string][math]::floor($DISK.Size/1024/1024/1024))", "$([string][math]::floor(($DISK.Size-$Disk.AllocatedSize)/1024/1024/1024))", "$($DISK.FriendlyName)"

            $y = $y + $XBO_Y
            $elements."Button$($DISK.Number)" = Get-FormButton "&$($DISK.Number)" $XBO_X $y
            $elements."Button$($DISK.Number)".Add_Click($XBO_FORMAT_DRIVE)
            $elements."Label$($DISK.Number)" = Get-FormLabel "$($DISK_DISPLAY)`n" 45 ($y+3)
        }
    }
    $y = $y + 30
    $elements.ButtonC = Get-FormButton "ca&Ncel" $XBO_X $y 80
    $elements.ButtonC.Add_Click($XBO_FORMAT_DRIVE)

    $y = $y + $XBO_Y
    $formfooter = "`n* Select $($disktype) Xbox One Drive . . .                                 *`n"
    $elements.LabelC = Get-FormLabel $formfooter $XBO_X $y

    $y = $y + $XBO_Y + $XBO_Y
    $elements.LabelD = Get-FormLabel $msg $XBO_X $y 'PaleVioletRed'

    Show-SystemDialog $elements

    Write-Output "`"$($global:XBO_FORMAT_DRIVE)`" was selected" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host

    if ($global:XBO_FORMAT_DRIVE -eq "caNcel") {
        Exit-DriveSelection
    } elseif (Test-ForC $global:XBO_FORMAT_DRIVE) {
        $err = "`nFound C: on selected disk `"$($global:XBO_FORMAT_DRIVE)`", please try again`n"
        $global:XBO_FORMAT_DRIVE = Select-DiskMenuForm $err $disktype $diskskip
    }

    return $global:XBO_FORMAT_DRIVE
} # function Select-DiskMenuForm($msg, $disktype, $diskskip)


# Was :DskPrtLett rewritten from bat
# Rather than assume proper partition order 1-5 to assign drive letters
# Assign by matching the FileSystemLabel
function Set-PartitionLetters($disknum) {
    $output  = "`n"
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
                $output += Write-ProgressDialog "* Assigning partition letter $($TEMP_CONTENT_LETTER): to '$($TEMP_CONTENT_LABEL)' . . .`n" 1 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $TEMP_CONTENT_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($USER_CONTENT_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($USER_CONTENT_LETTER): to '$($USER_CONTENT_LABEL)' . . .`n" 2 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $USER_CONTENT_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($SYSTEM_SUPPORT_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($SYSTEM_SUPPORT_LETTER): to '$($SYSTEM_SUPPORT_LABEL)' . . .`n" 3 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_SUPPORT_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($SYSTEM_UPDATE_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($SYSTEM_UPDATE_LETTER): to '$($SYSTEM_UPDATE_LABEL)' . . .`n" 4 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE_LETTER -ErrorAction SilentlyContinue
                break
            }
            "$($SYSTEM_UPDATE2_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($SYSTEM_UPDATE2_LETTER): to '$($SYSTEM_UPDATE2_LABEL)' . . .`n" 5 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE2_LETTER -ErrorAction SilentlyContinue
                break
            }

            # DUPlicatE letters
            "D$($TEMP_CONTENT_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($TEMP_CONTENT_LDUPE): to 'D$($TEMP_CONTENT_LABEL)' . . .`n" 1 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $TEMP_CONTENT_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($USER_CONTENT_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($USER_CONTENT_LDUPE): to 'D$($USER_CONTENT_LABEL)' . . .`n" 2 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $USER_CONTENT_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($SYSTEM_SUPPORT_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($SYSTEM_SUPPORT_LDUPE): to 'D$($SYSTEM_SUPPORT_LABEL)' . . .`n" 3 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_SUPPORT_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($SYSTEM_UPDATE_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($SYSTEM_UPDATE_LDUPE): to 'D$($SYSTEM_UPDATE_LABEL)' . . .`n" 4 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE_LDUPE -ErrorAction SilentlyContinue
                break
            }
            "D$($SYSTEM_UPDATE2_LABEL)" {
                $output += Write-ProgressDialog "* Assigning partition letter $($SYSTEM_UPDATE2_LDUPE): to 'D$($SYSTEM_UPDATE2_LABEL)' . . .`n" 5 5
                Set-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber -NewDriveLetter $SYSTEM_UPDATE2_LDUPE -ErrorAction SilentlyContinue
                break
            }
        } # switch ($VOLUME.FileSystemLabel)
    } # foreach($PART in $RESULT)
    return $output
} # function Set-PartitionLetters($disknum)


#
function Get-DriveSizeBytes($disknum) {
    return Get-Disk -Number $disknum | Select-Object -ExpandProperty Size
} # function Get-DriveSizeBytes($disknum)


# Was :ListPart rewritten from bat
function Get-PartitionList($disknum) {
    $PART_HEADER = "{0,-38} {1,-4} {2,-8} {3}" -f "GUID", "Dev", "Size", "Name"
    $output  = "`n$($PART_HEADER)`n"
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
    $output += "$($DISK_DISPLAY)`n"
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
        $output += "$($PART_DISPLAY)`n"
    }
    $output += "`n"
    return $output
} # function Get-PartitionList($disknum)


#
function Select-WarningMsgForm($msg, $creationtype) {
    [hashtable]$elements = [ordered]@{}
    # Reset $XBO_YES_NO from prior calls
    $XBO_YES_NO = { $global:XBO_YES_NO        = $this.Text -replace '[&]','' }

    $nowarn = @("c","d","f")
    if ($nowarn -contains $creationtype) {
        return
    }

    $y = $XBO_X
    $formheader = "$($global:XBO_CREATION_TEXT)"
    $elements.LabelA = Get-FormLabel $formheader $XBO_X $y 'PaleTurquoise'
    $y = $(Get-TextYaxis $formheader)

    $formheader = "$($msg)WARNING: This will erase all data on TARGET disk $($global:XBO_FORMAT_DRIVE). Continue?`n"
    $elements.LabelB = Get-FormLabel $formheader $XBO_X $y
    $y = $y + $(Get-TextYaxis $formheader)

    $y = $y + $XBO_Y
    $elements."ButtonY" = Get-FormButton "&Yes" $XBO_X $y
    $elements."ButtonY".Add_Click($XBO_YES_NO)
    $elements."ButtonN" = Get-FormButton "&No"  5$XBO_X $y
    $elements."ButtonN".Add_Click($XBO_YES_NO)

    Show-SystemDialog $elements

    if ($global:XBO_YES_NO -eq "No") {
        Exit-DriveSelection
    }
    return $global:XBO_YES_NO
} # function Select-WarningMsgForm($msg, $creationtype)


#
function Select-CopyMsgForm($msg) {
    [hashtable]$elements = [ordered]@{}
    # Reset $XBO_YES_NO from prior calls
    $XBO_YES_NO = { $global:XBO_YES_NO        = $this.Text -replace '[&]','' }

    $y = $XBO_X
    $formheader = "$($global:XBO_CREATION_TEXT)"
    $elements.LabelA = Get-FormLabel $formheader $XBO_X $y 'PaleTurquoise'
    $y = $(Get-TextYaxis $formheader)

    $formheader = "$($msg)`nWARNING: About to COPY data to TARGET disk $($global:XBO_FORMAT_DRIVE). Continue?`n"
    $elements.LabelB = Get-FormLabel $formheader $XBO_X $y
    $y = $y + $(Get-TextYaxis $formheader)

    $y = $y + $XBO_Y
    $elements."ButtonY" = Get-FormButton "&Yes" $XBO_X $y
    $elements."ButtonY".Add_Click($XBO_YES_NO)
    $elements."ButtonN" = Get-FormButton "&No"  5$XBO_X $y
    $elements."ButtonN".Add_Click($XBO_YES_NO)

    Show-SystemDialog $elements

    if ($global:XBO_YES_NO -eq "No") {
        Exit-DriveCopy
    }
    return $global:XBO_YES_NO
} # function Select-CopyMsgForm($msg)


#
function Get-FormattedMsg($creationtype, $disknum) {
    $nowarn = @("d", "f", "g")
    if ($nowarn -contains $creationtype) {
        return
    }
    return "`n* Disk $disknum will be formatted as an Xbox One Drive . . .                *`n"
} # function Get-FormattedMsg($creationtype, $disknum)


# Was :MsgMexists and :MsgDexists rewritten from bat
function Get-DriveStatusMsg($letter, $label) {
    $RESULT = Get-Volume -DriveLetter $letter -ErrorAction SilentlyContinue
    if ($RESULT.DriveLetter) {
        $output  = "* Found Drive $($letter): '$($label)'"
    } else {
        $output  = "* Missing Drive $($letter): '$($label)'"
    }
    return $output
} # function Get-DriveStatusMsg($letter, $label)


#
function Exit-DriveSelection {
    $output  = "`n* Xbox One Drive Selection Cancelled                                 *"
    Exit-ScriptForm $output
} # function Exit-DriveSelection


#
function Exit-DriveCopy {
    $partlist = Get-PartitionList $global:XBO_FORMAT_DRIVE
    $output  = "$($partlist)* Xbox One Drive Copy Cancelled                                      *"
    Exit-ScriptForm $output
} # function Exit-DriveCopy


#
function Exit-ScriptForm($msg) {
    [hashtable]$elements = [ordered]@{}

    $TIMESTAMP = Get-Date -UFormat "%Y.%m.%d %T"
    $exit = @"

* Script execution complete.
* Ended: $($TIMESTAMP)
* Script ran for $([math]::floor($STOPWATCH.Elapsed.TotalSeconds)) seconds

"@

    $y = $XBO_X
    $formheader = "$($global:XBO_CREATION_TEXT)"
    $elements.LabelA = Get-FormLabel $formheader $XBO_X $y 'PaleTurquoise'
    $y = $(Get-TextYaxis $formheader)

    $formheader = "$($msg)`n$($exit)"
    $elements.LabelB = Get-FormLabel $formheader $XBO_X $y
    $y = $y + $(Get-TextYaxis $formheader)

    $y = $y + $XBO_Y
    $elements.Button1 = Get-FormButton "fi&Nish" $XBO_X $y 80

    Show-SystemDialog $elements

    ### Restore console minimized (2) ###
    ### Change to 1 to restore to normal state ###
    $hideconsole::ShowConsoleWindow( 1 )

    # "Unhandled exception has occurred in a component in your application. If you click Continue. the application will ignore this error and attempt to continue."
    #Exit
} # function Exit-ScriptForm($msg)


#
function Exit-Script($msg) {
    Write-Output "$($msg)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Script execution complete." | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    $TIMESTAMP = Get-Date -UFormat "%Y.%m.%d %T"
    Write-Output "* Ended: $($TIMESTAMP)" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "* Script ran for $([math]::floor($STOPWATCH.Elapsed.TotalSeconds)) seconds" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Write-Output "" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host
    Get-Pause
    Exit
} # function Exit-Script($msg)


#
function Test-Letters($type) {
    [hashtable]$return = [ordered]@{}
    $output  = ""
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
            $output += "* Missing '$($labels[$i])' $($letters[$i]):`n"
            $ALL_OK = $FALSE
        }
    }
    $return.output = $output
    $return.exit   = $ALL_OK
    return $return
} # function Test-Letters($type)


# Was :RoboCopyAll rewritten from bat
function Backup-DirectCopy {
    $output  = "`n"
    $test = Test-Letters
    if ($test.exit) {
        $output += Copy-ProgressDialog "DirectCopy" "Temp_Content"    "$($TEMP_CONTENT_LETTER):"   "$($TEMP_CONTENT_LDUPE):"
        $output += Copy-ProgressDialog "DirectCopy" "User_Content"    "$($USER_CONTENT_LETTER):"   "$($USER_CONTENT_LDUPE):"
        $output += Copy-ProgressDialog "DirectCopy" "System_Support"  "$($SYSTEM_SUPPORT_LETTER):" "$($SYSTEM_SUPPORT_LDUPE):"
        $output += Copy-ProgressDialog "DirectCopy" "System_Update"   "$($SYSTEM_UPDATE_LETTER):"  "$($SYSTEM_UPDATE_LDUPE):"
        $output += Copy-ProgressDialog "DirectCopy" "System_Update_2" "$($SYSTEM_UPDATE2_LETTER):" "$($SYSTEM_UPDATE2_LDUPE):"
    } else {
        $output += "$($test.output)* Something is missing, cannot copy data`n"
    }
    return $output
} # function Backup-DirectCopy


# Was :RoboCopyRun <sourceVarName> <targetVarName> <lognameVarValue> rewritten from bat
function Invoke-RoboCopy($type, $logname, $source, $target) {
    $output  = "`n"
    if (-Not (Test-Path -Path "$($target)")) {
        $null = New-Item -Path "$($target)" -ItemType "directory" -Force
    }
    if (Test-Path -Path "$($target)") {
        $XBO_ROBOCOPY_LOG = "$($Env:TEMP)\RoboCopy-$($logname).log"
        $XBO_RUN = "`"$($XBO_ROBOCOPY)`" `"$($source)`" `"$($target)`" /XD `"`$RECYCLE.BIN`" `"System Volume Information`" /ZB /MIR /XJ /R:3 /W:3 /TS /FP /ETA /LOG:`"$($XBO_ROBOCOPY_LOG)`" /TEE"
        $output += "* Running $($type): $($XBO_RUN)`n"
        cmd /c "$($XBO_RUN)" 2>&1 | Tee-Object -FilePath $XBO_LOG -Append | Out-Null

        if ($type -eq "Backup") {
            # Unhide top level $target directory by removing the 'Hidden,System' Attributes
            Clear-ItemProperty -Path "$($target)" -Name Attributes
        }
    } else {
        $output += "* Target $($target) is missing, skipping . . .`n"
    }
    return $output
} # function Invoke-RoboCopy($type, $logname, $source, $target)


# Was :RoboPartSel rewritten from bat
function Select-RoboCopyPartitionForm($robotype) {
    [hashtable]$elements = [ordered]@{}

    $y = $XBO_X
    $formheader = "$($global:XBO_CREATION_TEXT)"
    $elements.LabelA = Get-FormLabel $formheader $XBO_X $y 'PaleTurquoise'
    $y = $(Get-TextYaxis $formheader)

    $formheader = "`nSelect partition $($robotype) type:`n"
    $elements.LabelB = Get-FormLabel $formheader $XBO_X $y
    $y = $y + $(Get-TextYaxis $formheader)

    $y = $y + $XBO_Y
    $elements.Button1 = Get-FormButton "&a" $XBO_X $y
    $elements.Button1.Add_Click($XBO_BACKUP_TYPE)
    $elements.Label1  = Get-FormLabel "`"System Update`" only (more important)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button2 = Get-FormButton "&b" $XBO_X $y
    $elements.Button2.Add_Click($XBO_BACKUP_TYPE)
    $elements.Label2  = Get-FormLabel "`"All Partitions`"     (less important)`n" 45 ($y+3)

    $y = $y + 30
    $elements.Button3 = Get-FormButton "ca&Ncel" $XBO_X $y 80
    $elements.Button3.Add_Click($XBO_BACKUP_TYPE)

    $y = $y + $XBO_Y
    $elements.Label4 = Get-FormLabel "`n" $XBO_X $y

    Show-SystemDialog $elements

    if ($global:XBO_BACKUP_TYPE -eq "caNcel") {
        Exit-DriveSelection
    }
    return $global:XBO_BACKUP_TYPE
} # function Select-RoboCopyPartitionForm($robotype)


# Was :RoboBackUpd rewritten from bat
function Backup-RoboCopy {
    $output  = "`n"
    $XBO_BACKUP_TYPE = Select-RoboCopyPartitionForm "Backup"
    if ($XBO_BACKUP_TYPE -eq "caNcel") { return }
    $test = Test-Letters $XBO_BACKUP_TYPE
    if ($test.exit) {
        if ($XBO_BACKUP_TYPE -eq "a") {
            $output += Copy-ProgressDialog "Backup" "System_Update"   "$($SYSTEM_UPDATE_LETTER):"  "$($SCRIPT_PATH)\System_Update"
        } else {
            $output += Copy-ProgressDialog "Backup" "Temp_Content"    "$($TEMP_CONTENT_LETTER):"   "$($SCRIPT_PATH)\Temp_Content"
            $output += Copy-ProgressDialog "Backup" "User_Content"    "$($USER_CONTENT_LETTER):"   "$($SCRIPT_PATH)\User_Content"
            $output += Copy-ProgressDialog "Backup" "System_Support"  "$($SYSTEM_SUPPORT_LETTER):" "$($SCRIPT_PATH)\System_Support"
            $output += Copy-ProgressDialog "Backup" "System_Update"   "$($SYSTEM_UPDATE_LETTER):"  "$($SCRIPT_PATH)\System_Update"
            $output += Copy-ProgressDialog "Backup" "System_Update_2" "$($SYSTEM_UPDATE2_LETTER):" "$($SCRIPT_PATH)\System_Update_2"
        }
    } else {
        $output += "$($test.output)* Something is missing, cannot copy data`n"
    }
    return $output
} # function Backup-RoboCopy


# Was :RoboRestUpd rewritten from bat
function Restore-RoboCopy {
    $output  = "`n"
    $XBO_BACKUP_TYPE = Select-RoboCopyPartitionForm "Restore"
    if ($XBO_BACKUP_TYPE -eq "caNcel") { return }
    $test = Test-Letters $XBO_BACKUP_TYPE
    if ($test.exit) {
        if ($XBO_BACKUP_TYPE -eq "a") {
            $output += Copy-ProgressDialog "Restore" "System_Update"   "$($SCRIPT_PATH)\System_Update"   "$($SYSTEM_UPDATE_LETTER):"
        } else {
            $output += Copy-ProgressDialog "Restore" "Temp_Content"    "$($SCRIPT_PATH)\Temp_Content"    "$($TEMP_CONTENT_LETTER):"
            $output += Copy-ProgressDialog "Restore" "User_Content"    "$($SCRIPT_PATH)\User_Content"    "$($USER_CONTENT_LETTER):"
            $output += Copy-ProgressDialog "Restore" "System_Support"  "$($SCRIPT_PATH)\System_Support"  "$($SYSTEM_SUPPORT_LETTER):"
            $output += Copy-ProgressDialog "Restore" "System_Update"   "$($SCRIPT_PATH)\System_Update"   "$($SYSTEM_UPDATE_LETTER):"
            $output += Copy-ProgressDialog "Restore" "System_Update_2" "$($SCRIPT_PATH)\System_Update_2" "$($SYSTEM_UPDATE2_LETTER):"
        }
    } else {
        $output += "$($test.output)* Something is missing, cannot copy data`n"
    }
    return $output
} # function Restore-RoboCopy


# Was :ChkDskAll rewritten from bat
function Repair-Partitions($disknum) {
    $output  = "`n"
    $Counter = 0
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber
    foreach($PART in $RESULT) {
        $Counter++
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
        $null = Write-ProgressDialog "$($PART_DISPLAY)`n" $Counter $RESULT.Count
        $output += "$($PART_DISPLAY)"
        $output += Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Repair-Volume -OfflineScanAndFix
        $output += "`n"
    }
    return "$($output)`n"
} # function Repair-Partitions($disknum)


# Was :GdWipe rewritten from bat
# Destructive: As the name implies, cleans a disk by removing all partition information and un-initializing it
#              then initializes the disk as GPT
function Clear-TargetDisk($disknum) {
    $output  = "`n"
    $output += Write-ProgressDialog "* Removing existing partitions with Clear-Disk . . .`n" 1 1
    # Force the disk online due to possible signature collisions
    Set-Disk -Number $disknum -IsOffline $FALSE
    # -ErrorAction SilentlyContinue
    Clear-Disk -Number $disknum -RemoveData -RemoveOEM -Confirm:$FALSE
    # Creates a small Reserved partition which needs to be removed
    Initialize-Disk -Number $disknum -PartitionStyle GPT -Confirm:$FALSE -ErrorAction SilentlyContinue
    Remove-Partition -DiskNumber $disknum -PartitionNumber 1 -Confirm:$FALSE -ErrorAction SilentlyContinue
    return $output
} # function Clear-TargetDisk($disknum)


#
function Test-DriveTooSmall($disksize, $disknum) {
    $output    = "`n"
    $exit      = $FALSE
    $size500gb = @("a")
    $size1tb   = @("b")
    $size2tb   = @("c")
    $sizeauto  = @("d", "e", "f")
    $XBOX_DRIVE_SIZE_IN_BYTES = Get-DriveSizeBytes($disknum)
    # Standard sizes are 500GB, 1TB, or 2TB minimum
    if ($size2tb -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_2TB + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            $output += "* Xbox One Drive TARGET Too Small for 2TB Standard Minimum           *`n"
            Exit-ScriptForm $output
            $exit    = $TRUE
        }
    } elseif ($size1tb -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_1TB + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            $output += "* Xbox One Drive TARGET Too Small for 1TB Standard Minimum           *`n"
            Exit-ScriptForm $output
            $exit    = $TRUE
        }
    } elseif ($size500gb -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_500GB + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            $output += "* Xbox One Drive TARGET Too Small for 500GB Standard Minimum         *`n"
            Exit-ScriptForm $output
            $exit    = $TRUE
        }
    }
    # Non-Standard sizes are 120GB minimum
    if ($sizeauto -contains $disksize) {
        $XBOX_DRIVE_SIZE_IN_BYTES_MIN  = ([math]::floor(($XBOX_TEMP_SIZE_IN_BYTES + $XBOX_USER_SIZE_IN_BYTES_MIN + $XBOX_SUPPORT_SIZE_IN_BYTES + $XBOX_UPDATE_SIZE_IN_BYTES + $XBOX_UPDATE2_SIZE_IN_BYTES)))
        if ($XBOX_DRIVE_SIZE_IN_BYTES -lt $XBOX_DRIVE_SIZE_IN_BYTES_MIN) {
            $output += "* Xbox One Drive TARGET Too Small 120GB Non-Standard Minimum         *`n"
            Exit-ScriptForm $output
            $exit    = $TRUE
        }
    }
    return $exit
} # function Test-DriveTooSmall($disksize, $disknum)


# Was :GdStruct rewritten from bat
function Select-DiskLayoutForm($creationtype) {
    [hashtable]$elements = [ordered]@{}
    $standard = @("a")

    $y = $XBO_X
    $formheader = "$($global:XBO_CREATION_TEXT)"
    $elements.LabelA = Get-FormLabel $formheader $XBO_X $y 'PaleTurquoise'
    $y = $(Get-TextYaxis $formheader)

    $formheader = "`nSelect partition layout for TARGET disk $($global:XBO_FORMAT_DRIVE):`n"
    $elements.LabelB = Get-FormLabel $formheader $XBO_X $y
    $y = $y + $(Get-TextYaxis $formheader)

    $y = $y + $XBO_Y
    $elements.Button1 = Get-FormButton "&a" $XBO_X $y
    $elements.Button1.Add_Click($XBO_SIZE)
    $elements.Label1  = Get-FormLabel "500GB Standard (365GB)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button2 = Get-FormButton "&b" $XBO_X $y
    $elements.Button2.Add_Click($XBO_SIZE)
    $elements.Label2  = Get-FormLabel "1TB Standard   (781GB)`n" 45 ($y+3)

    $y = $y + $XBO_Y
    $elements.Button3 = Get-FormButton "&c" $XBO_X $y
    $elements.Button3.Add_Click($XBO_SIZE)
    $elements.Label3  = Get-FormLabel "2TB Standard  (1662GB)`n" 45 ($y+3)

    if ($standard -contains $creationtype) {
        $y = $y + 30
        $elements.Button4 = Get-FormButton "ca&Ncel" $XBO_X $y 80
        $elements.Button4.Add_Click($XBO_SIZE)
    } else {
        $y = $y + $XBO_Y
        $elements.Button4 = Get-FormButton "&d" $XBO_X $y
        $elements.Button4.Add_Click($XBO_SIZE)
        $elements.Label4  = Get-FormLabel "Autosize Non-Standard w/ 500GB Disk GUID (11GB MIN 1947GB MAX)`n" 45 ($y+3)

        $y = $y + $XBO_Y
        $elements.Button5 = Get-FormButton "&e" $XBO_X $y
        $elements.Button5.Add_Click($XBO_SIZE)
        $elements.Label5  = Get-FormLabel "Autosize Non-Standard w/ 1TB Disk GUID   (11GB MIN 1947GB MAX)`n" 45 ($y+3)

        $y = $y + $XBO_Y
        $elements.Button6 = Get-FormButton "&f" $XBO_X $y
        $elements.Button6.Add_Click($XBO_SIZE)
        $elements.Label6  = Get-FormLabel "Autosize Non-Standard w/ 2TB Disk GUID   (11GB MIN 1947GB MAX)`n" 45 ($y+3)

        $y = $y + 30
        $elements.Button7 = Get-FormButton "ca&Ncel" $XBO_X $y 80
        $elements.Button7.Add_Click($XBO_SIZE)
    }

    $y = $y + $XBO_Y
    $elements.Label8 = Get-FormLabel "`n" $XBO_X $y

    Show-SystemDialog $elements

    if ($global:XBO_SIZE -eq "caNcel") {
        Exit-DriveSelection
    }

    return $global:XBO_SIZE
} # function Select-DiskLayoutForm($creationtype)


# Was :GdGuid rewritten from bat
# Set disk and partition GUID values, no direct way to do this using PowerShell/diskpart?
# Does:    Sets GUID values of the disk and partitions in proper 1-5 order
# Doesn't: Create partitions, format as NTFS, set FileSystemLabel, or drive letters
function Invoke-GdiskGuid($creationtype, $disksize, $disknum) {
    $output  = "`n"
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

    $output += Write-ProgressDialog "* Changing disk and partition GUID values with $($XBO_GDISK) . . .`n" 1 1

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
    return $output
} # function Invoke-GdiskGuid($creationtype, $disksize, $disknum)


# Destructive: Formats the partition and sets the volume label
# Does:    Formats as NTFS and sets the FileSystemLabel based on partition GUID values
# Doesn't: Create partitions, set GUID values, or drive letters
function Format-VolumeLabel($disknum) {
    $output  = "`n"
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        switch ($PART.Guid.ToUpper() -replace '[{}]','') {
            "$($TEMP_CONTENT_GUID)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) '$($TEMP_CONTENT_LABEL)' . . .`n" 1 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($TEMP_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($USER_CONTENT_GUID)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) '$($USER_CONTENT_LABEL)' . . .`n" 2 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($USER_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_SUPPORT_GUID)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) '$($SYSTEM_SUPPORT_LABEL)' . . .`n" 3 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SYSTEM_SUPPORT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE_GUID)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) '$($SYSTEM_UPDATE_LABEL)' . . .`n" 4 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SYSTEM_UPDATE_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE2_GUID)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) '$($SYSTEM_UPDATE2_LABEL)' . . .`n" 5 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "$($SYSTEM_UPDATE2_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }

            # DUPlicatE letters
            "$($TEMP_CONTENT_GDUPE)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($TEMP_CONTENT_LABEL)' . . .`n" 1 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($TEMP_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($USER_CONTENT_GDUPE)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($USER_CONTENT_LABEL)' . . .`n" 2 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($USER_CONTENT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_SUPPORT_GDUPE)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($SYSTEM_SUPPORT_LABEL)' . . .`n" 3 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($SYSTEM_SUPPORT_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE_GDUPE)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($SYSTEM_UPDATE_LABEL)' . . .`n" 4 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($SYSTEM_UPDATE_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
            "$($SYSTEM_UPDATE2_GDUPE)" {
                $output += Write-ProgressDialog "* Formatting and labeling partition $($PART.PartitionNumber) 'D$($SYSTEM_UPDATE2_LABEL)' . . .`n" 5 5
                $VOLUME | Format-Volume -FileSystem NTFS -NewFileSystemLabel "D$($SYSTEM_UPDATE2_LABEL)" | Tee-Object -FilePath $XBO_LOG -Append | Out-Null
                break
            }
        }
    }
    return $output
} # function Format-VolumeLabel($disknum)


# Was :LabelVol rewritten from bat
# Non-destructive: Sets the volume label
# Rather than assume proper partition order 1-5 to assign the FileSystemLabel
# Assign by matching the GUID
# Does:    Set the FileSystemLabel based on partition GUID values
# Doesn't: Create partitions, format as NTFS, set GUID values, or drive letters
function Set-VolumeLabel($disknum) {
    $output  = "`n"
    $RESULT = Get-Partition -DiskNumber $disknum | Sort-Object -Property PartitionNumber
    foreach($PART in $RESULT) {
        $VOLUME = Get-Partition -DiskNumber $disknum -PartitionNumber $PART.PartitionNumber | Get-Volume
        switch ($PART.Guid.ToUpper() -replace '[{}]','') {
            "$($TEMP_CONTENT_GUID)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to '$($TEMP_CONTENT_LABEL)' . . .`n" 1 5
                $VOLUME | Set-Volume -NewFileSystemLabel "$($TEMP_CONTENT_LABEL)"
                break
            }
            "$($USER_CONTENT_GUID)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to '$($USER_CONTENT_LABEL)' . . .`n" 2 5
                $VOLUME | Set-Volume -NewFileSystemLabel "$($USER_CONTENT_LABEL)"
                break
            }
            "$($SYSTEM_SUPPORT_GUID)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to '$($SYSTEM_SUPPORT_LABEL)' . . .`n" 3 5
                $VOLUME | Set-Volume -NewFileSystemLabel "$($SYSTEM_SUPPORT_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE_GUID)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to '$($SYSTEM_UPDATE_LABEL)' . . .`n" 4 5
                $VOLUME | Set-Volume -NewFileSystemLabel "$($SYSTEM_UPDATE_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE2_GUID)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to '$($SYSTEM_UPDATE2_LABEL)' . . .`n" 5 5
                $VOLUME | Set-Volume -NewFileSystemLabel "$($SYSTEM_UPDATE2_LABEL)"
                break
            }

            # DUPlicatE letters
            "$($TEMP_CONTENT_GDUPE)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to 'D$($TEMP_CONTENT_LABEL)' . . .`n" 1 5
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($TEMP_CONTENT_LABEL)"
                break
            }
            "$($USER_CONTENT_GDUPE)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to 'D$($USER_CONTENT_LABEL)' . . .`n" 2 5
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($USER_CONTENT_LABEL)"
                break
            }
            "$($SYSTEM_SUPPORT_GDUPE)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to 'D$($SYSTEM_SUPPORT_LABEL)' . . .`n" 3 5
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($SYSTEM_SUPPORT_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE_GDUPE)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to 'D$($SYSTEM_UPDATE_LABEL)' . . .`n" 4 5
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($SYSTEM_UPDATE_LABEL)"
                break
            }
            "$($SYSTEM_UPDATE2_GDUPE)" {
                $output += Write-ProgressDialog "* Setting volume label on partition $($PART.PartitionNumber) to 'D$($SYSTEM_UPDATE2_LABEL)' . . .`n" 5 5
                $VOLUME | Set-Volume -NewFileSystemLabel "D$($SYSTEM_UPDATE2_LABEL)"
                break
            }
        }
    }
    return $output
} # function Set-VolumeLabel($disknum)


# Was :GdPart rewritten from bat
# Does:    Creates properly sized Xbox One partitions in proper 1-5 order
# Doesn't: Format as NTFS, set FileSystemLabel, set GUID values, or drive letters
function New-Partitions($disksize, $disknum) {
    $output  = "`n"
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
            $output += "* Disk larger than 2TB, Limiting User Content to 1.9TB               *`n"
            $XBOX_USER_SIZE_IN_BYTES = $XBOX_USER_SIZE_IN_BYTES_MAX
        }
    }

    $output += Write-ProgressDialog "* Creating partition 1 with $($XBOX_TEMP_SIZE_IN_BYTES) bytes . . .`n" 1 5
    New-Partition -DiskNumber $disknum -Size $XBOX_TEMP_SIZE_IN_BYTES | Out-Null

    $output += Write-ProgressDialog "* Creating partition 2 with $($XBOX_USER_SIZE_IN_BYTES) bytes . . .`n" 2 5
    New-Partition -DiskNumber $disknum -Size $XBOX_USER_SIZE_IN_BYTES | Out-Null

    $output += Write-ProgressDialog "* Creating partition 3 with $($XBOX_SUPPORT_SIZE_IN_BYTES) bytes . . .`n" 3 5
    New-Partition -DiskNumber $disknum -Size $XBOX_SUPPORT_SIZE_IN_BYTES | Out-Null

    $output += Write-ProgressDialog "* Creating partition 4 with $($XBOX_UPDATE_SIZE_IN_BYTES) bytes . . .`n" 4 5
    New-Partition -DiskNumber $disknum -Size $XBOX_UPDATE_SIZE_IN_BYTES | Out-Null

    $output += Write-ProgressDialog "* Creating partition 5 with $($XBOX_UPDATE2_SIZE_IN_BYTES) bytes . . .`n" 5 5
    New-Partition -DiskNumber $disknum -Size $XBOX_UPDATE2_SIZE_IN_BYTES | Out-Null
    return $output
} # function New-Partitions($disksize, $disknum)


#
function Select-MainMenuHandler($XBO_CREATION_TYPE) {
    # Sending function arguments as variables with Add_Click doesn't work
    # In which case grab the Sender (button) Text instead
    if (-Not ($XBO_CREATION_TYPE)) {
        $XBO_CREATION_TYPE = $this.Text -replace '[&]',''
    }
    Write-Output "`"$XBO_CREATION_TYPE`" was selected" | Tee-Object -FilePath $XBO_LOG -Append | Write-Host

    $XBO_SOURCE_DRIVE = ""
    switch ($XBO_CREATION_TYPE) {
        "a" {
            $global:XBO_CREATION_TEXT = "(a) Replace/Upgrade without a working original drive  (Standard Only)`n"
            break
        }
        "b" {
            $global:XBO_CREATION_TEXT = "(b) Replace/Upgrade keeping original drive data    (Standard and Non)`n"
            $XBO_SOURCE_DRIVE = Select-DiskMenuForm "" "SOURCE"
            if ($XBO_SOURCE_DRIVE -eq "caNcel") { return }
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Set-PartitionLetters $XBO_SOURCE_DRIVE
            Close-ProgressDialog
            break
        }
        "c" {
            $global:XBO_CREATION_TEXT = "(c) Fix GUID values without formatting the drive   (Standard and Non)`n"
            break
        }
        "d" {
            $global:XBO_CREATION_TEXT = "(d) Backup `"System Update`" to current directory    (Standard and Non)`n"
            break
        }
        "e" {
            $global:XBO_CREATION_TEXT = "(e) Restore `"System Update`" from current directory (Standard and Non)`n"
            break
        }
        "f" {
            $global:XBO_CREATION_TEXT = "(f) Check all partitions for file system errors    (Standard and Non)`n"
            break
        }
        "g" {
            $global:XBO_CREATION_TEXT = "(g) Wipe drive of all partitions and GUID values   (Standard and Non)`n"
            break
        }
        "h" {
            $global:XBO_CREATION_TEXT = "(h) DirectCopy without formatting the target drive (Standard and Non)`n"
            $XBO_SOURCE_DRIVE = Select-DiskMenuForm "" "SOURCE"
            if ($XBO_SOURCE_DRIVE -eq "caNcel") { return }
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Set-PartitionLetters $XBO_SOURCE_DRIVE
            Close-ProgressDialog
            break
        }
    }

    $XBO_TARGET_DRIVE = Select-DiskMenuForm "" "TARGET" $XBO_SOURCE_DRIVE
    if ($XBO_TARGET_DRIVE -eq "caNcel") { return }

    $partlist = Get-PartitionList $XBO_TARGET_DRIVE
    if ($(Select-WarningMsgForm "$($partlist)" $XBO_CREATION_TYPE) -eq "No") { return }

    $formattedmsg = Get-FormattedMsg $XBO_CREATION_TYPE $XBO_TARGET_DRIVE
    $output  = "$($formattedmsg)"

    # Split out to the various Xbox One drive creation types
    switch ($XBO_CREATION_TYPE) {
        "a" {
            $XBO_SIZE = Select-DiskLayoutForm $XBO_CREATION_TYPE
            if ($XBO_SIZE -eq "caNcel" -Or $(Test-DriveTooSmall $XBO_SIZE $XBO_TARGET_DRIVE)) { return }
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Clear-TargetDisk $XBO_TARGET_DRIVE
            $output += New-Partitions $XBO_SIZE $XBO_TARGET_DRIVE
            $output += Invoke-GdiskGuid $XBO_CREATION_TYPE $XBO_SIZE $XBO_TARGET_DRIVE
            $output += Format-VolumeLabel $XBO_TARGET_DRIVE
            $output += Set-PartitionLetters $XBO_TARGET_DRIVE
            Close-ProgressDialog
            break
        }
        "b" {
            $XBO_SIZE = Select-DiskLayoutForm $XBO_CREATION_TYPE
            if ($XBO_SIZE -eq "caNcel" -Or $(Test-DriveTooSmall $XBO_SIZE $XBO_TARGET_DRIVE)) { return }
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Clear-TargetDisk $XBO_TARGET_DRIVE
            $output += New-Partitions $XBO_SIZE $XBO_TARGET_DRIVE
            $output += Invoke-GdiskGuid $XBO_CREATION_TYPE $XBO_SIZE $XBO_TARGET_DRIVE
            $output += Format-VolumeLabel $XBO_TARGET_DRIVE
            $output += Set-PartitionLetters $XBO_TARGET_DRIVE
            Close-ProgressDialog
            if ($(Select-CopyMsgForm "$($output)") -eq "No") { return }
            $output = Backup-DirectCopy
            break
        }
        "c" {
            $XBO_SIZE = Select-DiskLayoutForm $XBO_CREATION_TYPE
            if ($XBO_SIZE -eq "caNcel") { return }
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Invoke-GdiskGuid $XBO_CREATION_TYPE $XBO_SIZE $XBO_TARGET_DRIVE
            $output += Set-VolumeLabel $XBO_TARGET_DRIVE
            $output += Set-PartitionLetters $XBO_TARGET_DRIVE
            Close-ProgressDialog
            break
        }
        "d" {
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Set-PartitionLetters $XBO_TARGET_DRIVE
            Close-ProgressDialog
            $output += Backup-RoboCopy
            if ($global:XBO_BACKUP_TYPE -eq "caNcel") { return }
            break
        }
        "e" {
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Set-PartitionLetters $XBO_TARGET_DRIVE
            Close-ProgressDialog
            $output += Restore-RoboCopy
            if ($global:XBO_BACKUP_TYPE -eq "caNcel") { return }
            break
        }
        "f" {
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Repair-Partitions $XBO_TARGET_DRIVE
            Close-ProgressDialog
            break
        }
        "g" {
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Clear-TargetDisk $XBO_TARGET_DRIVE
            Close-ProgressDialog
            break
        }
        "h" {
            $XBO_SIZE = Select-DiskLayoutForm $XBO_CREATION_TYPE
            if ($XBO_SIZE -eq "caNcel" -Or $(Test-DriveTooSmall $XBO_SIZE $XBO_TARGET_DRIVE)) { return }
            Open-ProgressDialog "Starting $global:XBO_CREATION_TEXT"
            $output += Set-PartitionLetters $XBO_TARGET_DRIVE
            Close-ProgressDialog
            if ($(Select-CopyMsgForm "$($output)") -eq "No") { return }
            $output = Backup-DirectCopy
            break
        }
    }

    $partlist = Get-PartitionList $XBO_TARGET_DRIVE
    $drivemsg = Get-DriveStatusMsg $SYSTEM_UPDATE_LETTER $SYSTEM_UPDATE_LABEL
    Exit-ScriptForm "$($output)$($partlist)$($drivemsg)"
} # function Select-MainMenuHandler($XBO_CREATION_TYPE)


### Handle script processing and output ###

$hideconsole = Add-Type -MemberDefinition $signature1 -Name Hide -Namespace HideConsole -ReferencedAssemblies System.Runtime.InteropServices -PassThru

### Get the introduction dialog ###
Get-IntroForm
# All remaining script processing moved to:
# Select-MainMenuHandler($XBO_CREATION_TYPE)
