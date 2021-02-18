<#
.SYNOPSIS
	Install Az modules into an Automation Account.
.DESCRIPTION
	This script installs Az modules into an Automation Account.
.NOTES
	Author: Colin Roche, MOQdigital
	For: QBANK
	ChangeLog:
		1.0.0 - CR, 2020-06-23 - First Release.
		1.0.1 - CR, 2020-06-30 - Updated $ModuleNames format.
		1.0.2 - CR, 2020-07-09 - Updated error action.
		1.0.3 - CR, 2020-07-09 - Fixed spelling errors.
#>

param (
    # Environment Name.
    [Parameter(Mandatory = $true, HelpMessage = "Automation Account Name.")]
    [String]
    $AutomationAccountName,
    # Environment Name.
    [Parameter(Mandatory = $true, HelpMessage = "Resource Group Name.")]
    [String]
    $ResourceGroupName
)

# Set the error action prefernce to 'Stop' for the script.
$ErrorActionPreference = "Stop"

# List of module names to be imported by the script.
$ModuleNames = @(
    "Az.Accounts",
    "Az.Storage",
    "Az.Resources",
    "Az.Automation",
    "Az.Compute",
    "Az.Network"
)
# Loop through each module to perform the import.
foreach ($ModuleName in $ModuleNames) {
    Write-Output ("`nImporting module {0}" -f $ModuleName)
    # Retrieve the current module details to get the latest version for import.
    $ModuleDetails = Find-Module $ModuleName
    # Import the module.
    $CreateModule = New-AzAutomationModule -AutomationAccountName $AutomationAccountName -ResourceGroupName $ResourceGroupName -Name $ModuleName -ContentLinkUri ("https://www.powershellgallery.com/api/v2/package/{0}/{1}" -f $ModuleName, $ModuleDetails.Version)
    # If the module being imported in "Az.Accounts", the script needs to wait for the import to complete as all other modules are dependant on this module.
    if ($ModuleName -eq "Az.Accounts") {
        Write-Output ("`nWaiting for module {0} import to complete..." -f $ModuleName)
        # Check the status of the current import and wait for the ProvisioningState to be "Succeeded" before continuing to the next import.
        $CheckModule = Get-AzAutomationModule -Name $ModuleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
        # While the provisioning state is not "Succeeded", wait for 10 seconds, then check again. Once the state changes to "Succeeded, continue with the other imports."
        while ($CheckModule.ProvisioningState -ne "Succeeded") {
            Start-Sleep -Seconds 10
            $CheckModule = Get-AzAutomationModule -Name $ModuleName -ResourceGroupName $ResourceGroupName -AutomationAccountName $AutomationAccountName
        }
    }
}
