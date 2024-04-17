<#
.SYNOPSIS
    Detects if Fusion360 is up to date for use with SCCM. 
.DESCRIPTION
    This script checks the locally installed version of Fusion 360 vs the most up to date version online then returns a boolean. True for needs update and false for no update needed. 
    Intended for use with SCCM for a Detection script to be used with a remediation baseline to automatically update Fusion360 when an update is released. 
.NOTES
    Author: Austen Ewald
    Version: 1.2
    Date published: 04/10/2024
    Only looks at the default installed directory of fusion360 when it is installed with the --globalinstall parameter 
    JSON files are saved to %Programdata%/Autodesk
    Change variables as needed below this section
#>

$StreamerDir = "C:\Program Files\Autodesk\webdeploy\meta\streamer"
$InfoFileJSON = "C:\ProgramData\Autodesk\FusionVersion.JSON"
$LastestReleaseJSON = "C:\ProgramData\Autodesk\FusionVersionLatest.JSON"

if (!(Test-Path $StreamerDir)) {
    # Write-Host "Path Not Found"
    return $false
}

try {
    $Fusion360LatestJsonURL = "https://dl.appstreaming.autodesk.com/production/67316f5e79bc48318aa5f7b6bb58243d/73e72ada57b7480280f7a6f4a289729f/full.json"
    Invoke-WebRequest $Fusion360LatestJsonURL -OutFile $LastestReleaseJSON
}
catch {
    $_
    exit 1
}

$Appversion = Get-ChildItem -Directory "c:\Program Files\Autodesk\webdeploy\meta\streamer" | Sort-Object -Property Name -Descending
if ($Appversion.count -gt 1) {
    $Appversion = $Appversion.Name[0]
}
else {
    $Appversion = $Appversion.Name
}

Start-Process -FilePath "$StreamerDir\$($Appversion)\streamer.exe" -ArgumentList "--globalinstall", "--process query", "--infofile `"$InfoFileJSON`"" -PassThru -Wait -Verb RunAs -WindowStyle Hidden | Out-Null

$FusionLatestInfo = Get-Content -Raw -Path $LastestReleaseJSON | ConvertFrom-Json
$FusionInfo = Get-Content -Raw -Path $InfoFileJSON | ConvertFrom-Json

$LatestVersion = $FusionLatestInfo.'build-version'
$CurrentVersion = $FusionInfo.manifest.'build-version'

if ($CurrentVersion -lt $LatestVersion) {
    Return $true
}
else {
    return $false
}
