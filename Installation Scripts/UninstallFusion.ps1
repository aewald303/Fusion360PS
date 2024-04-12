<#
.SYNOPSIS
    Uninstalls Fusion 360 globally for use in lab environment.
.DESCRIPTION
    This script uninstalls Fusion360 globally on the computer for all users.
    Outputs a log file to C:\Windows\Temp(Can be changed in the variable below this section)
    Cleans up any registry entries created by my other scripts. 

.NOTES
    Author: Austen Ewald
    Version: 1.2
    Date published: 04/10/2024
    Only looks at the default installed directory of fusion360 when it is installed with the --globalinstall parameter 
    Change variables as needed below this section
#>

$StreamerDir = "C:\Program Files\Autodesk\webdeploy\meta\streamer"
$UninstallLogPath = "C:\Windows\Temp\FusionUninstall.log"

if (!(Test-Path $StreamerDir)){
    Exit 1
}

$Appversion = Get-ChildItem -Directory "c:\Program Files\Autodesk\webdeploy\meta\streamer" | Sort-Object -Property Name -Descending
if ($Appversion.count -gt 1){
    $Appversion = $Appversion.Name[0]
}
else {
    $Appversion = $Appversion.Name
}
try {
    Start-Process -FilePath "$StreamerDir\$($Appversion)\streamer.exe" -ArgumentList "--globalinstall", "--process uninstall", "--quiet", "--logfile `"$UninstallLogPath`"" -PassThru -Wait -Verb RunAs -WindowStyle Hidden
}
catch {
    $_
    Exit 1
}

Remove-Item 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item 'C:\Program Files\Autodesk\webdeploy' -Recurse -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item 'C:\ProgramData\Autodesk\FusionVersion.JSON' -Force -Confirm:$false -ErrorAction SilentlyContinue
Remove-Item 'C:\ProgramData\Autodesk\FusionVersionLatest.JSON' -Force -Confirm:$false -ErrorAction SilentlyContinue

exit 0



