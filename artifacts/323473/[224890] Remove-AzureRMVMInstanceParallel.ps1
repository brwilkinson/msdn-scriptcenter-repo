Function Remove-AzureRMVMInstanceParallel {
[cmdletbinding(SupportsShouldProcess,ConfirmImpact='High')]
 Param (
    [parameter(mandatory)]
    [String]$ResourceGroup,
    
    # The VM name to remove, regex are supported
    [parameter(mandatory)]
    [String]$VMName,

    # The Script will not wait for the background jobs by default, use this switch to wait
    [Switch]$Wait,
    
    # A configuration setting to also delete public IP's, off by default
    $RemovePublicIP = $False
 )

    # Remove the VM's and then remove the datadisks, osdisk, NICs
$jobs = Get-AzureRmVM -ResourceGroupName $ResourceGroup | Where Name -Match $VMName  | foreach {
        $vm=$_
        
        # avoid locks on the tokencache.dat file
        Start-Sleep -Seconds 3

        Start-Job -ScriptBlock {
            
            Try {
                $ctx = Import-AzureRmContext -path $home\ctx.json -ErrorAction Stop
                
                $resourceGroup = $using:Resourcegroup
                $VMName = $using:VM
                $RemovePublicIP = $using:RemovePublicIP
                # $ctx
                # Get-AzureRmResourceGroup -Name $resourceGroup
         
                Write-Verbose -Message "Connected to $($ctx.Subscription.Name)" -Verbose
                Write-Verbose -Message "The following resources were found:"
       

                $VM = Get-AzureRmVM -ResourceGroupName $resourceGroup -Name $VMName.Name -Verbose
        
                $DataDisks = @($VM.StorageProfile.DataDisks.Name)
                $OSDisk = @($VM.StorageProfile.OSDisk.Name)
                $NICS = @($VM.NetworkProfile.NetworkInterfaces)
                $ManagedDisk = $VM.StorageProfile.OsDisk.ManagedDisk
                ($OSDisk + $DataDisks)
                $NICS | Foreach ID

                # Remove confirm preference for background jobs
                #if ($pscmdlet.ShouldProcess("$($VM.Name)", "Removing VM, Disks and NIC: $($VM.Name)"))
                #{
                    Write-Warning -Message "Deleting VM:[$($VMName.Name)] from RG:[$resourceGroup]"
        
                    #DELETE Virtual Machine
                    $VM | Remove-AzureRmVM -Force -Confirm:$false

                    #DELETE NIC
                    $NICS | where {$_.ID} | ForEach-Object {
                        $NICName=split-path $_.ID -leaf
                        Write-Warning -Message "Removing NIC: $NICName"
                        $Nic = Get-AzureRmNetworkInterface -ResourceGroupName $ResourceGroup -Name $NICName
                        $Nic | Remove-AzureRmNetworkInterface -Force 
                        
                        # Optionally remove public ip's, will not save the static ip, if you need the same one, do not delete it.
                        if ($RemovePublicIP)
                        {
                            $nic.IpConfigurations.PublicIpAddress | where {$_.ID} | ForEach-Object {
                                $PublicIPName = Split-Path -Path $_.ID -leaf
                                Write-Warning -Message "Removing PublicIP: $PublicIPName"
                                $PublicIP = Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroup -Name $PublicIPName
                                $PublicIP | Remove-AzureRmPublicIpAddress -Force
                            }
                        }
                    }

                    if($ManagedDisk) {
                        #DELETE MANAGEDDISKS
                       ($OSDisk + $DataDisks) | where {$_} | ForEach-Object {
                            Write-Warning -Message "Removing Disk: $_"
                            Get-AzureRmDisk -ResourceGroupName $ResourceGroup -DiskName $_ | Remove-AzureRmDisk -Force
                        }
                    }
                    else {
                        #DELETE DATA DISKS 
                        $saname = ($VM.StorageProfile.OsDisk.Vhd.Uri -split '\.' | Select -First 1) -split '//' |  Select -Last 1
        
                        $SA = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name $saname
                        $VM.StorageProfile.DataDisks | foreach {
                            $disk = $_.Vhd.Uri | Split-Path -Leaf
                            Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
                            Get-AzureStorageBlob -Blob  $disk |
                            Remove-AzureStorageBlob  
                        }

                        #DELETE OS DISKS
                        $saname = ($VM.StorageProfile.OsDisk.Vhd.Uri -split '\.' | Select -First 1) -split '//' |  Select -Last 1
                        $disk = $VM.StorageProfile.OsDisk.Vhd.Uri | Split-Path -Leaf
                        $SA = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name $saname
                        Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
                        Get-AzureStorageBlob -Blob  $disk |
                        Remove-AzureStorageBlob  

                    }
            
                    # If you are on the network you can cleanup the Computer Account in AD            
                    # Get-ADComputer -Identity $a.OSProfile.ComputerName | Remove-ADObject -Recursive -confirm:$false
                
                # remove confirm preference for background jobs
                #}#PSCmdlet(ShouldProcess)
            }
            Catch {
                Write-Warning -Message 'You must save your Context first [Save-AzureRmContext -Path $home\ctx.json -Force]'
                Write-Warning $_
            }#Catch
            }#Start-Job
    }#Foreach-Object(Get-AzureRMVM)
sleep -Seconds 30
$jobs | Receive-Job -Keep

if ($Wait)
{
    sleep -Seconds 30
    $jobs | Wait-Job | Receive-Job
}
else
{
    Write-Warning "Run the following to view status of parallel delete`nGet-Job | Receive-Job -Keep"
}
}#Function