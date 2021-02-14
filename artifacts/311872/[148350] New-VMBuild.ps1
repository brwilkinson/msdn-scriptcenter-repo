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
     ##Requires –Modules hyper-v ,virtualmachinemanager
     #Requires –Version 3
     Param (
          # The Name of the Virtual Machine
          [parameter(Mandatory=$false,
                    ValueFromPipeline,
          ValueFromPipelineByPropertyName)]
          [alias("NewVMName")]
          [String]$VM,
          # The Hyper-V Server to add the VM to
          [String][ValidateSet("Hypv1","HypV2","Storage01")]
          $ComputerName = 'HypV1',
          # Set to $True to add the Data D:\ Drive
          [Switch]$IncludeDataDisk,
          # Generation 1 or 2 VM's, I think use 1 for anything less than Windows 8.
          [Int32][ValidateSet(1,2)]
          $VMGen = 2,
          # The MDT Task sequence ID
          [validateset('2012R2FULL','Chooselater')]
          [String]$OperatingSystem = '2012R2FULL',
          # VM Switch Name
          [String][ValidateSet('stdSwitch','LogicalSwitch-ProviderNetwork')]
          $SwitchName = 'LogicalSwitch-ProviderNetwork',
          # The Directory to Install the VM Files
          [String][ValidateSet("H:\VMs","C:\VMs")]
          [String]$BasePath = "H:\VMs",
          # The name of the VMM Server
          $VMMServer = 'vmm.contoso.com',
          # How to deploy the OS?
          [String][ValidateSet('PXE','ISO')]
          $BuildType = 'PXE',
          # The name of the WDS/PXE Server
          [String]$WDSServer = 'wds.consoto.com',
          # The name of the boot media in VMM library
          [String]$BootIso = 'LiteTouchPE_x64.iso',
          # Associate with VMM Cloud
          $CloudName = "Contoso-Cloud",
          # Launch the VMconnect window after build
          [Switch]$Launch,
          # The Notes in the virtual machine
          $Notes = @"
$VM for Contoso.COM
IP: DHCP
"@
     )
     begin {
        $i=0
        # recommend the hyper-v module 1.1 rather then 2.0.0.0
        Get-Module -Name Hyper-v | Remove-Module
        Import-Module hyper-v -RequiredVersion 1.1
     }#begin
     process {     
          $i++
          if (-not (hyper-v\Get-VM -ComputerName $ComputerName -Name $VM -ErrorAction SilentlyContinue))
          {
               
               $BaseFilePath = Join-Path -Path "\\$ComputerName" -ChildPath ($BasePath -replace ':','$')
               Write-Verbose -Message "BaseFilepath is $BaseFilePath" -Verbose
               if ((Test-Path -Path $BaseFilePath) -and ( -not (Test-Path -Path "$BaseFilePath\$VM\$VM.vhdx")))
               {
                    
                    $VMInfo = hyper-v\New-VM -ComputerName $ComputerName -Name $VM -MemoryStartupBytes (1GB) -SwitchName $SwitchName `
                    -NewVHDPath "$BasePath\$VM\$VM.vhdx" -NewVHDSizeBytes (140GB) -BootDevice CD -Path $BasePath -Generation $VMGen -Verbose 
                    
                    $VMInfo | hyper-v\Set-VM -ProcessorCount 4 -DynamicMemory -MemoryMinimumBytes (1GB) `
                    -MemoryMaximumBytes (8GB) -AutomaticStartAction StartIfRunning -AutomaticStopAction Save -AutomaticStartDelay 0  -Notes $Notes
                    
                    if ($SwitchName -eq 'LogicalSwitch-ProviderNetwork')
                    {
                         $VMInfo | hyper-v\Set-VMNetworkAdapterVlan -VlanId 20 -Access
                    }
                    
                    $VMInfo | hyper-v\Set-VMProcessor -Verbose -CompatibilityForMigrationEnabled $true
                    
                    $VMInfo | hyper-v\Get-VMIntegrationService | hyper-v\Enable-VMIntegrationService
                    
                    if ($IncludeDataDisk)
                    {
                         # Add Data drive for DATA
                         hyper-v\New-VHD  -ComputerName $ComputerName -Dynamic -SizeBytes (240GB) -Path "$BasePath\$VM\$VM-D.vhdx" -Verbose |
                              Select-Object -Property ComputerName,Path 
                         $VMInfo | hyper-v\Add-VMHardDiskDrive -Verbose -Path "$BasePath\$VM\$VM-D.vhdx"
                    }
                    
                    $VMInfo | hyper-v\Start-VM -Verbose | Out-Host
                    Start-Sleep -Seconds 15
                    $VMInfo = hyper-v\Get-VM -ComputerName $ComputerName -Name $VM
                    $MacAddress = $VMInfo | hyper-v\Get-VMNetworkAdapter -Verbose | Select-Object -First 1 -ExpandProperty MacAddress
                    $VMInfo | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MacAddress -PassThru
                    Write-Warning "$VM Created in VMM/HyperV with MAC Address: $MacAddress"
                    
                    # Find the VM in SCVMM.
                    $all = Read-SCVirtualMachine -VMHost $ComputerName
                    $SCVM = Get-SCVirtualMachine -VMMServer $VMMServer -Name $VM | 
                                Where-Object StatusString -NE 'missing' |
                                Sort-Object -Property AddedTime | Select-Object -First 1
                    
                    
                    if ($BuildType -eq 'ISO')
                    {
                         # Find the boot iso in the library, find the DVD drive and mount it.
                         $VirtualDVDDrive = Get-SCVirtualDVDDrive -VMMServer $VMMServer -VM $SCVM
                         $ISO = Get-SCISO -VMMServer $VMMServer -Name $BootIso
                         $mountresult = Set-SCVirtualDVDDrive -VirtualDVDDrive $VirtualDVDDrive -ISO $ISO -Link               
                    }
                    else
                    {
                         try {
                         # Call external custom function to create the PXE reservation
                         # allows the PXE for the given Mac address
                         BRW\Set-WDSPXEReservation -EA Stop -ComputerName ("TempDeploy" + $i) -MacAddress $MacAddress | 
                         Select DeviceName,DeviceID,BootImagePath | Format-List
                         }
                         catch
                         {
    Write-Warning $_
    @"
    Set-WDSPXEReservation -ComputerName "TempDeploy" -MacAddress $MacAddress | 
        Select DeviceName,DeviceID,BootImagePath
"@
                         }
                            if ($OperatingSystem -ne 'Chooselater')
                            {
                                 try {
                                    # custom function to creating the MDT reservation for the OS type with Mac address for zero touch builds.
                                    BRW\New-MDTReservation -MACAddress $MacAddress -ComputerName $VM -OperatingSystem $OperatingSystem
                                 }
                                 Catch {
                                    write-warning $_
                                 }
                            }

                    }
 
                    # Associate with VMM Cloud - uncomment if required, needs the virtualmachinemanager module
                    if ($CloudName)
                    {
                         $SCCloud = Get-SCCloud -Name $CloudName
                         
                         $SCVMCloud = Set-SCVirtualMachine -VM $SCVM -Cloud $SCCloud -Owner "$env:USERDOMAIN\$env:USERNAME" -Verbose
                    } 
                    
                    if ($Launch)
                    {
                         # Build Complete Open vmconnect.exe
                         vmconnect.exe $ComputerName $VM
                    }
               }
               elseif (-not (Test-Path -Path $BaseFilePath))
               {
                    write-warning -Message "$BasePath is not valid for $ComputerName"
               }
               else
               {
                    write-warning -Message "Virtual Disk: $BasePath\$VM\$VM.vhdx already exists!!!"
               }
          }
          else
          {
               Write-Warning -Message "$VM already exists!!! Output includes current MAC Address"
               $VMInfo = hyper-v\Get-VM -ComputerName $ComputerName -Name $VM -ErrorAction SilentlyContinue
               $MacAddress = $VMInfo | hyper-v\Get-VMNetworkAdapter -ErrorAction SilentlyContinue | Select-Object -First 1 -ExpandProperty MacAddress
               $VMInfo | Add-Member -MemberType NoteProperty -Name MACAddress -Value $MacAddress -PassThru -Force
          }
     }#Process
     
}#New-VMBuild

