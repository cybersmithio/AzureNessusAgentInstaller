#
# Update these variables
#
param(
    [String]$downloadurl,
    [String]$nessusagentlinkingkey,
    [String]$nessusagentgroup
)
$filename="NessusAgent.msi"
$downloadfile="c:\downloads\$filename"
$installerargs="NESSUS_SERVER=`"cloud.tenable.com:443`" NESSUS_GROUPS=`"$nessusagentgroup`" NESSUS_KEY=$nessusagentlinkingkey /qn"
$packagename="Nessus Agent"
$version="10.0.0"


#
# Just code below here
#
# Informational line, but it helps so much when debugging in the MEM logs
Write-Host "Starting powershell script to install $packagename $version"

# Check if the software is installed and check what version it is
$UninstallKey="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
$reg=[microsoft.win32.registrykey]::OpenRemoteBaseKey('LocalMachine',$computername) 
$regkey=$reg.OpenSubKey($UninstallKey) 
$subkeys=$regkey.GetSubKeyNames()
$foundflag=$false
$wrongversion=$false
foreach($key in $subkeys) {
  $thiskey=$UninstallKey+"\\"+$key
  $thisSubKey=$reg.OpenSubKey($thiskey)
  $DisplayName=$thisSubKey.GetValue("DisplayName")
  $DisplayVersion=$thisSubKey.GetValue("DisplayVersion")
  #Write-Host "Found $DisplayName installed."
  if ( $DisplayName -eq $packagename )
  {
    Write-Host "Found $packagename installed.  Version $DisplayVersion"
    $foundflag=$true
    if ( $DisplayVersion -ne $version )
    {
        Write-Host "Need to install $version"
        $wrongversion=$true
    }
  }
}

# If the software is not installed, then install it.
if ($foundflag -eq $false ) {
  Write-Host "Downloading $packagename"
  mkdir -f \downloads
  Invoke-WebRequest $downloadurl -Outfile $downloadfile
  Write-Host "Installing $packagename"
  if ( $installerargs -eq "" ) {
    Start-Process -FilePath $downloadfile
  } else {
    Start-Process -FilePath $downloadfile -ArgumentList $installerargs
  }
}

# If the software is not the right version, then install the new version
if ($wrongversion -eq $true ) {
  Write-Host "Installing different version"
  Write-Host "Downloading $packagename"
  mkdir -f \downloads
  Invoke-WebRequest $downloadurl -Outfile $downloadfile
  Write-Host "Installing $packagename"
  if ( $installerargs -eq "" ) {
    Start-Process -FilePath $downloadfile
  } else {
    Start-Process -FilePath $downloadfile -ArgumentList $installerargs
  }
}

# Informational line, but it helps so much when debugging in the MEM logs
Write-Host "Finished powershell script to install $packagename $version"

Write-Host "Confirming Nessus Agent is linked"
#Variables:
$linked=$false
$loopcount=0

while ( $linked -eq $false -and $loopcount -lt 3 ) {

    #Checking the status of the Nessus Agent
    #There are several fields output from this, and they should be this or we need to unlink and relink
    #   Running: Yes
    #   Linked to: cloud.tenable.com:443
    #   Link status: Connected...
    $output=& "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent status
    "$output" -match '^Running: (?<runstatus>[^\s]*).+Linked to: (?<linkedto>[^\s]*).+Link status: (?<linkstatus>[^\s]*)'

    Write-Host "Status:"$Matches['runstatus']
    Write-Host "Linked to:"$Matches['linkedto']
    Write-Host "Link Status:"$Matches['linkstatus']

    if ( $Matches['linkstatus'] -eq "Connected" ) {
        Write-Host "Nessus Agent is connected."
        "Nessus Agent is connected."
        Write-Output "Nessus Agent is connected."
        $linked=$true
    } elseif ( $Matches['linkstatus'] -eq "Not" ) {
        Write-Host "Nessus Agent does not appear to be connected."
        & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent link --cloud --key=$nessusagentlinkingkey --groups="$nessusagentgroup"
        Write-Host "Unlink of Nessus Agent executed."
    } else {
        Write-Host "Nessus Agent in unknown state."
        & "C:\Program Files\Tenable\Nessus Agent\nessuscli.exe" agent unlink
        Write-Host "Unlink of Nessus Agent executed."
    }
    $loopcount++
    sleep 10
}
