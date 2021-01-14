@Echo Off
SETLOCAL EnableDelayedExpansion
::  Author:  XFiX
::  Date:    2019/10/22
::  Version: 8.1
::
::  Summary:
::  Create a true Xbox One 500GB, 1TB, or 2TB filesystem
::  This process is not a hack anymore
::  Past methods stretched a 500GB's filesystem
::  Now creates a resettable 500GB/1TB/2TB drive on ANY Xbox One OG/S/X Console
::  USE AT YOUR OWN RISK
::
::  TODO: Add true multilingual support
::
::  Change History:
::  2016/06/30 - Initial Release (2.0) - XFiX
::  2016/07/20 - Added Partition Size Selection (3.0) - XFiX
::  2016/08/10 - Use devcon to reset USB drives (4.0 Removed 5.0) - XFiX
::  2016/10/18 - List Partition Sizes (4.0) - XFiX
::  2017/05/12 - Added Englishize Cmd v1.7a Support (5.0 Removed 8.0) - XFiX
::  2017/05/24 - Official 1TB and 2TB GUID Support (5.0) - XFiX
::  2017/12/11 - Added "Run as administrator" check (6.0) - XFiX
::  2017/12/11 - Non-Standard larger than 2TB Support (6.0) - XFiX
::  2017/12/11 - Robocopy Standard to Non-Standard (6.0) - XFiX
::  2018/01/03 - Added \Windows\System32\en-US check (6.0) - XFiX
::  2018/01/31 - Allow selection of disk 0 (6.1) - XFiX
::  2018/01/31 - Only Backup "System Update" (6.1) - XFiX
::  2018/02/01 - Added :ChkForC to avoid destroying C: (6.1) - JCRocky5, XFiX
::  2018/03/12 - Better check for drive letter availability (7.0) - XFiX
::  2018/03/12 - Copy data to a local drive when only one SATA adapter is available (7.0) - XFiX
::  2018/04/26 - Find and log the current system language code (7.0) - XFiX
::  2018/04/26 - Warn drive size limitations and limit to 2TB "User Content" (7.0) - XFiX
::  2018/05/29 - Logging and path improvements (7.0) - XFiX
::  2018/06/19 - Preserve ACLs with robocopy /COPYALL (7.0 Removed 8.0) - XFiX
::  2018/11/13 - Removed Englishize Cmd v1.7a Usage (8.0) - XFiX
::  2018/11/13 - Support systems with 10 or more attached drives (8.0) - XFiX
::  2019/10/22 - create_xbox_drive.bat now calls create_xbox_drive.ps1 (8.1) - XFiX
::
::  Credit History:
::  2013/11 - Juvenal of Team Xecuter created the first working Python script
::  http://team-xecuter.com/forums/threads/141568-XBOX-ONE-How-To-Install-A-Bigger-Hard-Drive-%21
::
::  2014/07 - Ludvik Jerabek created the first bash script
::  http://www.ludvikjerabek.com/2014/07/14/xbox-one-fun-with-gpt-disk/
::
::  2016/06 - XFiX created a Windows batch script based on the bash script
::  https://www.youtube.com/playlist?list=PLURaLwRqr6g14Pl8qLO0E4ELBBCHfFh1V
::
::  2017/05 - A1DR1K discovered the secret behind what differentiates
::  500GB, 1TB, and 2TB Xbox One system hard drives
::  https://www.reddit.com/user/A1DR1K


echo.
echo * Running: create_xbox_drive.ps1
echo * and enabling PowerShell scripts to be run directly with:
echo Set-ExecutionPolicy RemoteSigned
powershell Set-ExecutionPolicy RemoteSigned
:: Change to the calling script's working directory
cd /D %~dp0
powershell -ExecutionPolicy ByPass -File create_xbox_drive.ps1


:endall
ENDLOCAL
