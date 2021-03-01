Clear-Host
Write-Verbose "Setting Arguments" -Verbose
$StartDTM = (Get-Date)	

$MyConfigFileloc = "D:\MDTProduction\Applications\Nutanix_Settings.xml"
[xml]$MyConfigFile = (Get-Content $MyConfigFileLoc)

$CVM = $MyConfigFile.Settings.Nutanix.CVM
$User = $MyConfigFile.Settings.Nutanix.User
$Pwd = $MyConfigFile.Settings.Nutanix.Pwd
$Network = $MyConfigFile.Settings.Nutanix.NetUUID
$Container = $MyConfigFile.Settings.Nutanix.Container
$ISO = $MyConfigFile.Settings.Nutanix.ISO
$Password = ConvertTo-SecureString $Pwd -AsPlainText -Force
$csv = "$PSScriptRoot\VMList.csv"

# Add Module
Import-Module "C:\Program Files (x86)\Nutanix Inc\NutanixCmdlets\Modules\NutanixCmdletsPSSnapin.dll"

Write-Verbose "Connecting to Nutanix Cluster $CVM" -Verbose
Connect-NTNXCluster -server $CVM -username $User -password $Password -AcceptInvalidSSLCerts -ForcedConnection | out-null
Write-Host ""

foreach($vmLine in (Import-Csv -Path $csv -UseCulture)){

    $vmname = $vmline.VMName
    $taskid = $vmline.TaskID
    $ip = $vmline.VMStaticIP
    $sub = $vmLine.VMNetmask
    $gw = $vmline.VMGateway
    $dns1 = $vmLine.VMDns1
    $fqdn = $env:userdnsdomain
    $ou = $vmline.OU
    
    Write-Verbose "Creating $vmname" -Verbose
    New-NTNXVirtualMachine -Name $VMName -NumVcpus $vmline.vCPU -MemoryMb $vmline.vRAM

    $diskCreateSpec = New-NTNXObject -Name VmDiskSpecCreateDTO
    $diskcreatespec.containerName = "$Container"
    $diskcreatespec.sizeMb = $vmline.vDiskGB
    
    Start-Sleep -s 3
        
    # Set Random MAC address
    $VMMAC = Get-RandomMAC

    # Get the VmID of the VM
    $vminfo = Get-NTNXVM | where {$_.vmName -eq $VMName}
    $vmId = ($vminfo.vmid.split(":"))[2]

    # Set NIC for VM on default vlan (Get-NTNXNetwork -> NetworkUuid)
    $nic = New-NTNXObject -Name VMNicSpecDTO
    $nic.networkUuid = $Network
    $nic.macAddress = $VMMAC

    Add-NTNXVMNic -Vmid $vmId -SpecList $nic | out-null

    # Creating the Disk
    $vmDisk =  New-NTNXObject –Name VMDiskDTO
    $vmDisk.vmDiskCreate = $diskCreateSpec
 
    # Mount ISO Image
    $diskCloneSpec = New-NTNXObject -Name VMDiskSpecCloneDTO
    $ISOImage = (Get-NTNXImage | ?{$_.name -eq $ISO})
    $diskCloneSpec.vmDiskUuid = $ISOImage.vmDiskId
    #setup the new ISO disk from the Cloned Image
    $vmISODisk = New-NTNXObject -Name VMDiskDTO
    #specify that this is a Cdrom
    $vmISODisk.isCdrom = $true
    $vmISODisk.vmDiskClone = $diskCloneSpec
    $vmDisk = @($vmDisk)
    $vmDisk += $vmISODisk

    # Adding the Disk ISO to the VM
    Add-NTNXVMDisk -Vmid $vmId -Disks $vmDisk | out-null
                 
    Write-Verbose "Starting $vmname" -Verbose
    Set-NTNXVMPowerOn -Vmid $VMid | out-null

    Start-Sleep -s 180

    Write-Verbose "Deployment of $VMname started Successfully" -Verbose
    Write-Host ""
}

Write-Verbose "Stop logging" -Verbose
$EndDTM = (Get-Date)
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalSeconds) Seconds" -Verbose
Write-Verbose "Elapsed Time: $(($EndDTM-$StartDTM).TotalMinutes) Minutes" -Verbose