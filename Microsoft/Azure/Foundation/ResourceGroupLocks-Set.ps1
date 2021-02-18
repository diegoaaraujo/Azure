<#
.SYNOPSIS
	Locate Resource Groups without a lock and auto-add a lock to them.
.DESCRIPTION
	This script runs through each Resource Groups with no resource locks, auto locks them.
.NOTES
	Author: Colin Roche, MOQdigital
	For: MOQdigital
	ChangeLog:
		1.0.0 - CR, 2020-06-25 - First Release.
		1.0.1 - CR, 2020-06-30 - Updated RG list to not apply to.
		1.0.2 - CR, 2020-07-09 - Updated error action.
#>

# Set the error action prefernce to 'Stop' for the script.
$ErrorActionPreference = "Stop"

try {
    # Retrieve Azure credentials for the Automation Account Run As Account.
    $Connection = Get-AutomationConnection -Name AzureRunAsConnection
    # Login to the subscription with the Azure credentials.
    $ConnectionResult = Connect-AzAccount -ServicePrincipal -Tenant $Connection.TenantID -ApplicationId $Connection.ApplicationID -CertificateThumbprint $Connection.CertificateThumbprint
    # List all Resource Groups in the subscription.
    $ResourceGroups = Get-AzResourceGroup
    # Loop through each Resource Group Found.
    foreach ($ResourceGroup in $ResourceGroups) {
        # Retrieve the name of the Resource Group
        $ResourceGroupName = $ResourceGroup.ResourceGroupName
        # Check if the Resource Group has been marked with a "Do-Not-Lock" Tag or matches a system created Resource Group.
        if ($ResourceGroup.tags.lock -eq "Do-Not-Lock" -or $ResourceGroupName -match "AzureBackupRG*|cloud-shell-storage*|CloudShell*|NetworkWatcherRG*|dashboards*") {
            # Check if the Resource Group is locked.
            $Locked = Get-AzResourceLock -ResourceGroupName $ResourceGroupName
            # If the Resource Group has a lock, remove it.
            if ($Locked -ne $Null) {
                # Find the name of the lock.
                $LockName = $Locked.LockId.split("/")[-1]
                try {
                    # Remove the lock on the Resource Group.
                    Remove-AzResourceLock -LockName $LockName -Force -ResourceGroupName $ResourceGroupName
                }
                catch {
                    Write-Warning ("Failed to remove Resource Lock for {0}" -f $ResourceGroupName)
                    continue
                }
            }
        }
        else {
            # Check if the Resource Group is locked.
            $Locked = Get-AzResourceLock -ResourceGroupName $ResourceGroupName
            #  If the Resource Group has no lock, lock the Resource Group.
            if ($Locked -eq $Null) {
                try {
                    # Set a lock on the Resource Group.
                    Set-AzResourceLock -LockName $ResourceGroupName -LockLevel CanNotDelete -LockNotes "Auto-Added" -Force -ResourceGroupName $ResourceGroupName
                }
                catch {
                    Write-Warning ("Failed to create Resource Lock for {0}" -f $ResourceGroupName)
                    continue
                }
            }
        }
    }
}
catch {
    throw $_
}
