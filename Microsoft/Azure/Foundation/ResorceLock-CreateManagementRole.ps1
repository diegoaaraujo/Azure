<#
.SYNOPSIS
	Script to create an RBAC role for managing Resource Locks.
.DESCRIPTION
	This script creates an RBAC role for managing Resource Locks.
.EXAMPLE
	ResourceLock-CreateManegementRole.ps1 -SubscriptionID "abcd6ba9-abc3-abcd-abcc-abcb2941ae9d"
.NOTES
	Author: Colin Roche, MOQdigital
	For: MOQdigital
	ChangeLog:
		1.0.0 - CR, 2020-06-24 - First Release.
#>

param (
    # Environment Name.
    [Parameter(Mandatory = $true, HelpMessage = "ID of the subscription.")]
    [String]
    $SubscriptionID
)

# Set the error action prefernce to 'Stop' for the script.
$ErrorActionPreference = "Stop"

# Check to see if the PowerShell window is logged on to Azure by retrieving a list of Resource Groups. If not, start a login.
try { Get-AzResourceGroup -ErrorAction "stop" | Out-Null }catch { Login-AzAccount }

# Use 'Reader' as the base for the new role.
$BaseRoleTemplate = "Reader"
# Provide a name for the role.
$NewRoleName = "Resource Lock Management"
# Provide a description for the role.
$NewRoleDescription = "This role allows full control of resource locks."

#Check the current context subscription.
$SubscriptionCheck = (Get-AzContext).subscription.SubscriptionId
# If the current context subscription ID doesn't match the ID provided in the parameters, try to connect to the correct ID. If that fails, exit the script.
if ($SubscriptionCheck -ne $SubscriptionID) {
    try {
        Select-AzSubscription -Subscription $SubscriptionID
    }
    catch {
        Write-Output ("Unable to connect to SubscriptionID {0}. Exiting script for safety." -f $SubscriptionID)
        Return
    }
}

# Look for a role named Resource Lock Management. If not found, create one.
if (!($Checkrole = Get-AzRoleDefinition -Name $NewRoleName)) {
    # Try to create the role.
    try {
        $Role = Get-AzRoleDefinition $BaseRoleTemplate
        $Role.Id = $null
        $Role.IsCustom = $true
        $Role.Name = $NewRoleName
        $Role.Description = $NewRoleDescription

        $Role.Actions.Clear()
        $Role.Actions.Add("Microsoft.Authorization/locks/*")

        $Role.AssignableScopes.Clear()
        $Role.AssignableScopes.Add("/subscriptions/$SubscriptionId")
        New-AzRoleDefinition -Role $Role
    }
    catch {
        Write-Output "Failed to create the role."
        Throw $_
    }
}
# If the role name already exists in the subscription, output a message to screen.
else {
    Write-Output ""
    Write-Output ("{0} already exists in subscription {1}. Exiting script." -f $NewRoleName, $SubscriptionID)
    Write-Output ""
}
