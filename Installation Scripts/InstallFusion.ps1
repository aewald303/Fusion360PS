<#
.SYNOPSIS
    Installs Fusion 360 globally for use in lab environment.
.DESCRIPTION
    This script installs Fusion360 globally on the computer for all users.
    Outputs a log file to C:\Windows\Temp(Can be changed in the variable below this section)
    Creates a registry entry for Fusion360 so the applicaiton shows up in Settings-Apps and in add/remove programs by default. Set $AddToProgramsList varible to $false if you don't want this. 
.NOTES
    Author: Austen Ewald
    Version: 1.2
    Date published: 04/10/2024
    Put the Fusion admin install exe in the same folder as the scripts. 
    Only looks at the default installed directory of fusion360 when it is installed with the --globalinstall parameter 
    JSON files are saved to %Programdata%/Autodesk
    Change variables as needed below this section
#>

$StreamerDir = "C:\Program Files\Autodesk\webdeploy\meta\streamer"
$InstallLogPath = "C:\Windows\Temp\FusionInstall.log"
$ExeName = "Fusion Admin Install.exe"
$InfoFileJSON = "C:\ProgramData\Autodesk\FusionVersion.JSON"
$AddToProgramsList = $true


try {
    Start-Process -FilePath "$PSScriptRoot\$ExeName" -ArgumentList "--globalinstall", "--quiet", "--logfile `"$InstallLogPath`"" -PassThru -Wait -Verb RunAs -WindowStyle Hidden
}
catch {
    $_
    Exit 1
}
try {
    $Appversion = Get-ChildItem -Directory "C:\Program Files\Autodesk\webdeploy\meta\streamer" | Sort-Object -Property Name -Descending
    if ($Appversion.count -gt 1){
        $Appversion = $Appversion.Name[0]
    }
    else {
        $Appversion = $Appversion.Name
    }
    Start-Process -FilePath "$StreamerDir\$($Appversion)\streamer.exe" -ArgumentList "--globalinstall", "--process query", "--infofile `"$InfoFileJSON`"" -PassThru -Wait -Verb RunAs -WindowStyle Hidden
    Copy-Item -Path "$PSScriptRoot\UninstallFusion.ps1" -Destination "$StreamerDir" -Force -Confirm:$false
}
catch {
    $_
    Exit 1
}

if($AddToProgramsList){
    $FusionInfo = Get-Content -Raw -Path $InfoFileJSON | ConvertFrom-Json
    $IconPathRegex = '(?<={stream_tag}\/).+?(?=\/)'
    $CurrentVersion = $FusionInfo.manifest.'build-version'
    $IconPath = [regex]::Matches($($FusionInfo.manifest.'launcher-path'), $IconPathRegex).Value 
    $IconPath = "C:\Program Files\Autodesk\webdeploy\production\$IconPath\Fusion360.ico"
    #Making Sure App Info is up to date
    if((Test-Path -LiteralPath "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360") -ne $true) {  New-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360" -force -ea SilentlyContinue };
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'DisplayIcon' -Value "$IconPath" -PropertyType String -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'DisplayName' -Value 'Fusion360' -PropertyType String -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'DisplayVersion' -Value "$CurrentVersion" -PropertyType String -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'EstimatedSize' -Value 5000000 -PropertyType DWord -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'NoModify' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'NoRepair' -Value 1 -PropertyType DWord -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'Publisher' -Value 'Autodesk' -PropertyType String -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'UninstallString' -Value "$StreamerDir\UninstallFusion.ps1" -PropertyType String -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'QuietUninstallString' -Value "$StreamerDir\UninstallFusion.ps1" -PropertyType String -Force -ea SilentlyContinue;
    New-ItemProperty -LiteralPath 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Fusion360' -Name 'URLInfoAbout' -Value 'https://www.autodesk.com/products/fusion-360/' -PropertyType String -Force -ea SilentlyContinue;
}
exit 0

