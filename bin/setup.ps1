Write-Host @"
    ____  _____ ____               _               __                                
   / __ \/ ___// __ \___ _      __(_)_______  ____/ /                                
  / /_/ /\__ \/ /_/ / _ \ | /| / / / ___/ _ \/ __  /                                 
 / ____/___/ / _, _/  __/ |/ |/ / / /  /  __/ /_/ /                                  
/_/    /____/_/ |_|\___/|__/|__/_/_/   \___/\__,_/                                   
    ____  ____________  _____      ____           __        ____                     
   / __ \/ ____/ ___/ |/ /__ \    /  _/___  _____/ /_____ _/ / /__  _____            
  / /_/ / /    \__ \|   /__/ /    / // __ \/ ___/ __/ __ `/ / / _ \/ ___/            
 / ____/ /___ ___/ /   |/ __/   _/ // / / (__  ) /_/ /_/ / / /  __/ /                
/_/    \____//____/_/|_/____/  /___/_/ /_/____/\__/\__,_/_/_/\___/_/                 
 ____________________________________________________________________________________
/_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/_____/

"@

$Shell = New-Object -ComObject "WScript.Shell"
$7zipPath = "$env:ProgramFiles\7-Zip\7z.exe"
$workingDirectory = Get-Location


# Ensure 7-Zip is installed (Thanks PCSX2...)
if (-not (Test-Path -Path $7zipPath -PathType Leaf)) {
    Write-Host -ForegroundColor Red -BackgroundColor Black "You are missing 7-Zip which is required. Please download and install it before running this script."
	$helpText = @"
It appears that 7-Zip is not installed on your PC which is required to continue.`n`n
Press Yes to automatically download the installer
Press No to exit 
"@
	if ($Shell.Popup($helpText,0, "Error", 4) -eq 6) {
		Start-Process "https://www.7-zip.org/a/7z2201-x64.exe"
	}
	Exit 1
}

Set-Alias Start-SevenZip $7zipPath

# Determine and download latest release of PCSX2
$repo = "pcsx2/PCSX2"
$file = "PCSX2.7z"

$headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"
$releases = "https://api.github.com/repos/$repo/releases"

Write-Host Getting latest version of PCSX2...
$id = ((Invoke-WebRequest $releases | ConvertFrom-Json)[0].assets | where { $_.name.EndsWith("windows-64bit-Qt.7z") })[0].id

$download = "https://api.github.com/repos/$repo/releases/assets/$id"

Write-Host Dowloading latest release:
Write-Host $download
$headers.Add("Accept", "application/octet-stream")
Invoke-WebRequest -Uri $download -Headers $headers -OutFile $file

Write-Host Extracting PCSX2 base install...
Start-SevenZip x "$file" -y > $null
Remove-Item "$file" -Force

# Add custom folders for game data
Write-Host Creating necessary folders...
mkdir -Force hdd,games > $null

Write-Host Downloading and Installing PS2 HDD image...
$download = "http://patch.psrewired.com/hddimg/AllSocomMaps.zip"
Invoke-WebRequest -Uri $download -Headers $headers -OutFile hdd.zip
Expand-Archive hdd.zip -DestinationPath .\hdd 
Remove-Item hdd.zip -Force

Write-Host Configuring PCSX2...
Expand-Archive include.zip -DestinationPath . -Force

# PCSX2 DEV9 does not support local file paths for the HDD unfortunately, so we need
# to replace the local path in the config with whatever the current directory setup is
$newPath = (Join-Path -Path $workingDirectory -ChildPath 'hdd\AllSocomMaps.raw')
$pcsxConfigPath = (Join-Path -Path $workingDirectory -ChildPath 'inis\PCSX2.ini')
(Get-Content -path $pcsxConfigPath -Raw) -replace '\.\\hdd\\AllSocomMaps\.raw', "$newPath" | Set-Content -Path $pcsxConfigPath

# Cleanup and remove installer files
Write-Host Cleaning up...
Remove-Item include.zip -Force
Remove-Item .\bin -Force -Recurse
Remove-Item install.bat -Force

Write-Host -ForegroundColor Green "Done!"

$helpText = @"
Some additional configuration for controllers and game patches may still be required!`n
-- You will need to source your games and PS2 BIOS yourself. --`n
The BIOS must be placed within the bios/ folder.`n`n
The emulator has been set up to auto-discover games in the games/ folder where you ran this script.
If you wish to use a different folder, you may do so within the PCSX2 settings.
`n`nFor additional guides and support, visit our website https://psrewired.com
"@


$Shell.Popup($helpText,0, "Installation Complete!", 0)