<#
.Synopsis
   Build a new VM running on a Hyper-V Server
.DESCRIPTION
   Build a new VM running on a Hyper-V Server, insert boot disk to deploy from MDT
.EXAMPLE
    PS PS:\> New-VMBuild -VM DSCWeb

    Name   State   CPUUsage(%) MemoryAssigned(M) Uptime   Status            
    ----   -----   ----------- ----------------- ------   ------            
    DSCWeb Off     0           0                 00:00:00 Operating normally
    DSCWeb Running 0           1024              00:00:02 Operating normally
.EXAMPLE
    PS PS:\> New-VMBuild -VM 2008R2Server -IncludeDataDisk -VMGen 1

    Name         State   CPUUsage(%) MemoryAssigned(M) Uptime   Status            
    ----         -----   ----------- ----------------- ------   ------            
    2008R2Server Off     0           0                 00:00:00 Operating normally
    2008R2Server Running 0           1024              00:00:02 Operating normally   
.OUTPUTS
   Outputs the return from the Get-VM command with an additional MACAddress property added.
.NOTES
   Setup all of your ComputerName (Hyper-V Servers), SwitchNames as validate sets to prompt.
#>

function New-VMBuild {
[CmdletBinding()]
    #Requires –Modules hyper-v #,virtualmachinemanager
    #Requires –Version 3
    Param (
    # The Name of the Virtual Machine
    [parameter(Mandatory=$true,
               ValueFromPipeline,
               ValueFromPipelineByPropertyName)]
    [alias("NewVMName")]
    [String]$VM,
    # The Hyper-V Server to add the VM to
    [String][ValidateSet("Hypv1","HypV2")]
    $ComputerName = 'HypV1',
    # Set to $True to add the Data D:\ Drive
    [Switch]$IncludeDataDisk,
    # Generation 1 or 2 VM's, I think use 1 for anything less than Windows 8.
    [Int32][ValidateSet(1,2)]
    $VMGen = 2,
    # VM Switch Name
    [String][ValidateSet("Internet-Bridge","VMNet-US","VMNet-AU","VMNet-EU")]
    $SwitchName = "Internet-Bridge",
    # The Directory to Install the VM Files
    [String]$BasePath = "H:\VMs",
    # The Source path for all ISO's, VHD's etc
    [String]$Source = "H:\Source",
    # The path to the boot media (I use MDT to build)
    [String]$Boot = "$Source\LiteTouchPE_x64.iso",
    # Associate with VMM Cloud
    $CloudName = "BRW-Cloud",
    # The Notes in the virtual machine
    $Notes = @"
    $VM for Domain.COM
    IP: DHCP
"@
)

    if (-not (hyper-v\Get-VM -ComputerName $ComputerName -Name $VM -ErrorAction SilentlyContinue))
    {

        if (-not (Test-Path -Path "$BasePath\$VM\$VM.vhdx"))
        {
        
            hyper-v\New-VM -ComputerName $ComputerName -Name $VM -MemoryStartupBytes (1GB) -NewVHDPath "$BasePath\$VM\$VM.vhdx" `
             -NewVHDSizeBytes (140GB) -BootDevice CD -SwitchName $SwitchName -Path $BasePath -Generation $VMGen

            hyper-v\Set-VM -ComputerName $ComputerName -Name $VM -ProcessorCount 4 -DynamicMemory -MemoryMinimumBytes (1GB) `
             -MemoryMaximumBytes (8GB) -AutomaticStartAction StartIfRunning -AutomaticStopAction Save -AutomaticStartDelay 0  -Notes $Notes

            hyper-v\Set-VMDvdDrive -ComputerName $ComputerName -Path $Boot -VMName $VM
            
            hyper-v\Set-VMProcessor -ComputerName $ComputerName -VMName $VM -CompatibilityForMigrationEnabled $true

            if ($IncludeDataDisk)
            {
                # Add Data drive for DATA
                hyper-v\New-VHD -Dynamic -SizeBytes (240GB) -Path "$BasePath\$VM\$VM-D.vhdx"
                hyper-v\Add-VMHardDiskDrive -ComputerName $ComputerName -VMName $VM -Path "$BasePath\$VM\$VM-D.vhdx"
            }

            hyper-v\Get-VMIntegrationService -ComputerName $ComputerName -VMName $VM | hyper-v\Enable-VMIntegrationService
    
            hyper-v\Start-VM -ComputerName $ComputerName -Name $VM | Out-Host
            Sleep -Seconds 2
            $VMInfo = hyper-v\Get-VM -ComputerName $ComputerName -Name $VM
            $MacAddress = $VMInfo | hyper-v\Get-VMNetworkAdapter | select -First 1 -ExpandProperty MacAddress
            $VMInfo | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MacAddress -PassThru

            <#
            # Associate with VMM Cloud - uncomment if required, needs the virtualmachinemanager module
            if ($CloudName)
            {
                $SCCloud = virtualmachinemanager\Get-SCCloud -Name $CloudName
                virtualmachinemanager\Set-SCVirtualMachine -VM $VM -Cloud $SCCloud -Owner "$env:USERDOMAIN\$env:USERNAME"
            }
            #>
        }
        else
        {
            "Virtual Disk: $BasePath\$VM\$VM.vhdx already exists!!!"
        }
    }
    else
    {
        Write-Warning -Message "$VM already exists!!!"
        $VMInfo = hyper-v\Get-VM -ComputerName $ComputerName -Name $VM
        $MacAddress = $VMInfo | hyper-v\Get-VMNetworkAdapter | select -First 1 -ExpandProperty MacAddress
        $VMInfo | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MacAddress -PassThru -Force
    }

}#New-VMBuild

