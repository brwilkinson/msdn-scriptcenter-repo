<#
CSV Template
============
templatevm,vmhost,custspec,vmname,ipaddress,subnet,gateway,vlan,notes,appowner
W2K8-R2-X64,esxwcdcdap003.domain.org,W2K8-R2-X64,OBIWCDCDVM001,10.185.136.103,255.255.254.0,10.185.136.1,QA-Test-App-Win_236,OBIEE Dev,Mrs Some User
============

templatevm : W2K8-R2-X64
vmhost     : vmhost.domain.org
custspec   : W2K8-R2-X64
vmname     : WSTWCDCDVM001
ipaddress  : 10.185.136.200
subnet     : 255.255.254.0
gateway    : 10.185.136.1
vlan       : QA-Test-App-Win_236
notes      : Monitoring Testing
appowner   : xyz

#>
##########################################################
Function global:Start-VMDeploy {


param (
         $Path,
         $Stepplus,
         [Switch]$Reset
      )

if ($Reset)
    {
        $Globali = $Null
        $Global:Step = $Null
        $Global:VMCSV_Builds = $Null
        $Global:StartTime = $Null
        break
    }


if (!$VMCSV_Builds)
    {
        New-Variable -Name i -Value 0 -Scope Global -Force
        New-Variable -Name Step -Value 1 -Scope Global -Force
        New-Variable -Name StartTime -Value (Get-Date) -Scope Global -Force
    }    

New-Variable -Name VMCSV_Builds -Value @(Import-Csv -Path $Path) -Scope Global -Force

If ($Stepplus)
    {
        $Global:Step = $Stepplus
    }

$VMCSV_Builds
"Step:  $Step"
$VMCSV_Builds | % {

	# map out the variables
	$templatevm = $_.templatevm
	#$datastore = $_.datastore
	$vmhost = $_.vmhost
	$custspec = $_.custspec
	$vmname = $_.vmname
	$ipaddr = $_.ipaddress
	$subnet = $_.subnet
	$gateway = $_.gateway
	$pdns = "10.185.98.100"
	$sdns = "10.134.2.100"
	$vlan = $_.vlan
    $description = $_.notes
    $appowner = $_.appowner


"`n==>VM " + $global:i + " " + $vmname

if ($Global:Step -eq "-1")
   {
    #Step 1
        # A - Connect VM
        #Disconnect-VM 1
        #Disconnect-VM 3
        #Disconnect-VM 2
        #Connect-VM 2
        # Presume you are already connected to VCenter
    }
    
if ($Global:Step -eq "1")
   {    
    if (!(Get-VM $vmname -ErrorAction 0))
        {
            #A - Find the DataStore
            $DataStore = (Get-VMHost -Name $vmhost | Get-Datastore | 
            # Exclude some data stores if you like
            #Where-Object {$_.Type -eq "VMFS" -and $_.Name -notmatch "CDCDEV11_SP" -and $_.Name -notmatch "datastore"} |
            Sort-Object -Descending -Property FreeSpaceMB | Select-Object -First 1).Name
            
            # B - Setup the IP address
            Get-OSCustomizationSpec $custspec | Get-OSCustomizationNicMapping | 
            Set-OSCustomizationNicMapping -IpMode UseStaticIp -IpAddress $ipaddr -SubnetMask $subnet -DefaultGateway $gateway -Dns $pdns,$sdns
            
            # C - Copy the Template and apply customizations
            $item = New-VM -Template $templatevm -VMHost $vmhost -Name $vmname -Datastore $Datastore -DiskStorageFormat 'Thick' -Description $description -OSCustomizationSpec $custspec -RunAsync
            "`n Step 1 is now being run.`n"
            Get-Task | ? {$_.id -eq $Item.id} |
            Foreach-Object {
                $VMtask = @{
                    State           = $_.State
                    PercentComplete = $_.PercentComplete
                    StartTime       = $_.StartTime
                    Job             = $_.Name
                    }
                New-Object psobject -Property $VMtask
                }
            
        }
    else
        {
            "`nVM aleady exists, checking for running tasks . .`n"
            $VMID = (Get-Vm -Name $vmname).ID
            $Task = @(Get-Task | ? {($_.Name -eq "CloneVM_Task") -and ($_.StartTime -gt $Global:StartTime)})
            $Task[$global:i] | Foreach-Object {
                $VMtask=@{
                    State           = $_.State
                    PercentComplete = $_.PercentComplete
                    StartTime       = $_.StartTime
                    Job             = $_.Name
                    }
            New-Object psobject -Property $VMtask
            } | Select-Object State, Percentcomplete
            if ($Task[$global:i].finishtime -le (get-date))
                {
                    $Global:i++
                    if ($VMCSV_Builds.count -eq $i)
                        {
                            "Task is complete, go onto the next step (2).`n"
                            $Global:Step++
                            "Moving onto step $Step`n"
                            $Global:i = 0
                        }
                }
            elseif (!$Task[$i].finishtime)
                {
                    Write-Host "Task is $($Task[$i].PercentComplete) % complete."
                    $i++
                }                
        }
   }

if ($Global:Step -eq "2")
   {                
    # Step 2
    # A - Get the VM and setup the VLAN - Set the Network Name (I often match PortGroup names with the VLAN name)
    $Global:VMStatus = GET-VM $vmname | Get-NetworkAdapter
    if (!$Global:VMStatus)
        {
            "Please wait for ALL VM's to build before running this step . ."
            $Global:i--
        }
    
    if (!(($Global:VMStatus.NetworkName -eq $vlan) -and (($Global:VMStatus.ConnectionState).StartConnected)))
        {
            Get-VM -Name $vmname | Get-NetworkAdapter | Set-NetworkAdapter -StartConnected $true -NetworkName $vlan -Confirm:$false
        }
    else
        {
            $Global:i++
            if ($VMCSV_Builds.count -eq $i)
                {            
                    "`nThe network is set correctly, go onto the next step (3).`n"
                    $Global:Step++
                    "Moving onto step $Step`n"
                    $Global:i = 0
                }            
        }
   }

if ($Global:Step -eq "3")
   {
    
    # Step 3
    # A - Start the VM   
    $VMStatus = GET-VM $vmname
    if ($VMStatus.PowerState -ne "PoweredOn")
        {
            GET-VM $vmname | Start-vm | select PowerState, Version, Description, Guest
            $Global:i++
        }
    elseif ($VMCSV_Builds.count -eq $Global:i)
        { 
            "`n$vmname is $($VMStatus.PowerState), you can move onto the next step (4)."
            $Global:Step++
            "Moving onto step $Step`n"
            $Global:i = 0
        }
     else
        {
            $Global:i++
            
        }             
           
   }

# Wait around 20 minutes before running this
if ($Global:Step -eq "4")
   {
    # Step 4
    # A - Check the VM is part of the domain and then move it to the correct OU
    "`n Step 4 is now being run, This will test of the Server has been added to the domain correctly`n" 
    
    if (Get-QADComputer $vmname )
        {
            "`nYou can now log onto the System it is part of the domain`n"
            Get-QADComputer -Name $vmname | select ParentContainer, DnsName
            "Moving the Server to the correct OU"
            Get-QADComputer -Name $vmname | Move-QADObject -NewParentContainer 'OU=Servers,OU=Hospital,DC=nyumc,DC=org' | select ParentContainer, DnsName
            
            $Global:i++
            if ($VMCSV_Builds.count -eq $i)
                { 
                    $Global:Step++
                    "Moving onto step $Step`n"
                    $Global:i = 0
                }                        
        }
    else
        {
            "`nVM is still building and is not yet part of the domain, try again soon`n"
        }
   }

# Add the build details to the VM
if ($Global:Step -eq "5")
   {
    if (-not (Get-CustomAttribute -Name CreatedBy))
        {
            New-CustomAttribute -Name "CreatedBy" -TargetType VirtualMachine
        }
    if (-not (Get-CustomAttribute -Name CreatedOn))
        {
            New-CustomAttribute -Name "CreatedOn" -TargetType VirtualMachine
        }    
    if (! (Get-CustomAttribute -Name Owner))
        {
            New-CustomAttribute -Name "Owner" -TargetType VirtualMachine
        }     
    if (! (Get-CustomAttribute -Name AppContact))
        {
            New-CustomAttribute -Name "AppContact" -TargetType VirtualMachine
        }     
    
    $VM = Get-vm $vmname
    If (-NOT ($VM).CustomFields['CreatedBy']) 
    {
        Write-Host "Looking for creator of $($vmname.name)"
        Try {
            $event = $VM | Get-VIEvent -MaxSamples 500000 -Types Info | Where {
                $_.GetType().Name -eq "VmBeingDeployedEvent" -OR $_.Gettype().Name -eq "VmCreatedEvent" -or $_.Gettype().Name -eq "VmRegisteredEvent"`
                 -or $_.Gettype().Name -eq "VmClonedEvent"
                }#End Where
            If (($event | Measure-Object).Count -eq 0) {
                $username = "Unknown"
                $created = "Unknown"
                }#End If
            Else {
                If ([system.string]::IsNullOrEmpty($event.username)) {
                    $username = "Unknown"
                    }#End If
                Else {
                    $username = $event.username
                    }#End Else
                $created = $event.CreatedTime
                }#End Else
            }
        Catch {
            Write-Warning "$($Error[0])"
            Return
            }
    }#End If
        
        Write-Host "Updating $($vm.name) attributes"
        if($username)
            {        
                $vm | Set-Annotation -CustomAttribute "CreatedBy" -Value $username  -ErrorAction 0 | Out-Null
            }
        if($created)
            {        
                $vm | Set-Annotation -CustomAttribute "CreatedOn" -Value $created  -ErrorAction 0 | Out-Null
            }
        if($description)
            {
                $vm | Set-Annotation -CustomAttribute "Owner" -Value $description  -ErrorAction 0 | Out-Null
            }
        if($appowner)
            {
                $vm | Set-Annotation -CustomAttribute "AppContact" -Value $appowner -ErrorAction 0 | Out-Null   
            }
        $Global:i++
            if ($VMCSV_Builds.count -eq $i)
                { 
                    $Global:Step++
                    "Moving onto step $Step`n"
                    $Global:i = 0
                }    
        
   }# End Step 5

# This is a post build step.
if ($Global:Step -eq "6")
   {
    # Step 5
    # Adds the group the the local Admin Group
    [Array]$AdminGroups = "WSET-ADM-01" #,"OBIEE-ADM-01" #, "sqladmin", "CTXInstaller", "Syngo-ADM-01"
    if ($AdminGroups -ne "")
        {
            # This script is available for download 
            # http://gallery.technet.microsoft.com/scriptcenter/5ed5c22d-32bf-4d6b-85a0-4f1d47086616
            \\Server\scripts$\AddLocalAdmin\Add-LocalAdmin.ps1 -Group $AdminGroups -Computer $ipaddr   
        }
    "`n Step 6 is now being run, adding $AdminGroups to the local Administrators group."

            $Global:i++
            if ($VMCSV_Builds.count -eq $i)
                { 
                    $Global:Step++
                    "Moving onto step $Step`n"
                    $Global:i = 0
                }
    
    # Disconnect from Host
    #Disconnect-VM 2
   }   
if ($Global:Step -eq "7")
   {
    # Step 5
    $Global:VMCSV_Builds = $Null
    "`n`nBuild is now complete!!!"
   }

   
}# Foreach-object

}#Start-VMDeploy 