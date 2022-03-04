# Assumes all systems are x64

Import-Module Az.Compute
$connectionName = "AzureRunAsConnection"
$nessusLinkingKey=Get-AutomationVariable -Name NessusLinkingKey
$windowsScriptUrl=Get-AutomationVariable -Name NessusWindowsInstallScript
$windowsBinaryUrl=Get-AutomationVariable -Name NessusWindowsInstallBinary
$windowsAgentGroup="AbliminalAzureWindows"
$ubuntuScriptUrl=Get-AutomationVariable -Name NessusUbuntuInstallScript
$ubuntuBinaryUrl=Get-AutomationVariable -Name NessusUbuntuInstallBinary
$linuxAgentGroup="AbliminalAzureLinux"

"Logging into Azure"
try
{
    $Conn = Get-AutomationConnection -Name $connectionName
	$tenantId=$Conn.TenantID
	$appId=$Conn.ApplicationID
	$certThumbprint=$Conn.CertificateThumbprint
	$subscription=$Conn.SubscriptionId
    "Logging in to Azure tenant $tenantId with app ID $appId and cert thumbprint $certThumbprint and subscription $subscription"

	Connect-AzAccount -ServicePrincipal -Tenant $Conn.TenantID -ApplicationId $Conn.ApplicationID -CertificateThumbprint $Conn.CertificateThumbprint

    "Log in completed"
}
catch {
    "Some error occured when trying to log in."
	if (!$servicePrincipalConnection)
    {
        "Connection not found."
		$ErrorMessage = "Connection $connectionName not found."
		$ErrorMessage
        throw $ErrorMessage
    } else{
        "Another exception"
        Write-Error -Message $_.Exception
		$_.Exception
        throw $_.Exception
    }
}

"Getting list of VMs"
$azVMs = Get-AzVM -status

#"List of VMs"
#$azVms

"Downloading script to install Nessus Agent"
Invoke-WebRequest $windowsScriptUrl -Outfile WindowsScriptToRun.ps1

"Run script on each VM"
foreach ($vm in $azVMs)
{
	"---------------------------------------------------------------------"
	$VmName=$vm.Name
	$VmRG=$vm.ResourceGroupName
	$OsProfile=$vm.OsProfile
	$VmStatus=$vm.PowerState

	if( $VmStatus -eq "VM running") {
		if ($vm.OsProfile.WindowsConfiguration) {
			"Running Windows script on $VmName in resource group $VmRG"
			Invoke-AzVMRunCommand -ResourceGroupName $VmRG -Name $VmName -CommandId 'RunPowerShellScript' -ScriptPath 'WindowsScriptToRun.ps1' -Parameter @{"downloadurl"=$windowsBinaryUrl; "nessusagentlinkingkey"=$nessusLinkingKey; "nessusagentgroup"=$windowsAgentGroup}
            "Ran script to install Nessus Agent"
		} elseif ($vm.OsProfile.LinuxConfiguration) {
			$linuxType=$vm.StorageProfile.ImageReference.offer
			"Linux type is $linuxType"
			"Running Linux script on $VmName in resource group $VmRG"
            if($linuxType -eq "UbuntuServer") {
                "Downloading install script from $ubuntuScriptUrl"
                Invoke-WebRequest $ubuntuScriptUrl -Outfile LinuxScriptToRun.sh
                "Running install script"
                "linuxBinaryUrl: $ubuntuBinaryUrl"
                "nessusagentlinkingkey: $nessusLinkingKey"
                "nessusagentgroup: $linuxAgentGroup"
			    Invoke-AzVMRunCommand -ResourceGroupName $VmRG -Name $VmName -CommandId 'RunShellScript' -ScriptPath 'LinuxScriptToRun.sh' -Parameter @{"linuxBinaryUrl"=$ubuntuBinaryUrl; "nessusagentlinkingkey"=$nessusLinkingKey; "nessusagentgroup"=$linuxAgentGroup}
                "Ran script to install Nessus Agent"
            }
		} else {
			"Unknown OS, not running a script"
		}
	} else {
		"VM is not running, cannot install Nessus Agent"
	}

}

