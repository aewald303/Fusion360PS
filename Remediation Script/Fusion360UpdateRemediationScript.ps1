<#
.SYNOPSIS
    Updates Fusion360 when run using streamer.exe. 
.DESCRIPTION
    This script updates Fusion360 when run and creates a file called LastUpdateCheck.Tag in the streamer directory with the date of the last time the script ran successfully.
    Intended to be used as an Intune/SCCM remediation script
    Updates the registry entry for Fusion360 created by my install script so the application shows up in Settings-Apps and in add/remove programs by default. Set $AddToProgramsList variable to $false if you don't want this. 
.NOTES
    Author: Austen Ewald
    Version: 1.2
    Date published: 04/10/2024
    Only looks at the default installed directory of fusion360 when it is installed with the --globalinstall parameter 
    Change variables as needed below this section
#>

$StreamerDir = "C:\Program Files\Autodesk\webdeploy\meta\streamer"
$UpdateLogPath = "C:\Windows\Temp\FusionUpdate.log"
$LastrunDate = get-date -Format "MM/dd/yyyy"
$InfoFileJSON = "C:\ProgramData\Autodesk\FusionVersion.JSON"
$AddToProgramsList = $true

if(Test-Path $UpdateLogPath){ Remove-Item -Path $UpdateLogPath -Force }
$Appversion = Get-ChildItem -Directory "c:\Program Files\Autodesk\webdeploy\meta\streamer" | Sort-Object -Property Name -Descending
if ($Appversion.count -gt 1){
    $Appversion = $Appversion.Name[0]
}
else {
    $Appversion = $Appversion.Name
}
try {
    Start-Process -FilePath "$StreamerDir\$($Appversion)\streamer.exe" -ArgumentList "--globalinstall", "--process update", "--quiet", "--logfile `"$UpdateLogPath`"" -PassThru -Wait -Verb RunAs -WindowStyle Hidden
    Set-Content -Path "$StreamerDir\LastUpdateCheck.tag" -Value "$LastrunDate"
    if($AddToProgramsList){
        Start-Process -FilePath "$StreamerDir\$($Appversion)\streamer.exe" -ArgumentList "--globalinstall", "--process query", "--infofile `"$InfoFileJSON`"" -PassThru -Wait -Verb RunAs -WindowStyle Hidden
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
    Exit 0
}
catch {
    $_
    Exit 1
}
