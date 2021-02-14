Function Remove-AzureRMVMInstanceResource {
[cmdletbinding(SupportsShouldProcess,ConfirmImpact='High')]
 Param (
    [parameter(mandatory)]
    [String]$ResourceGroup,
    
    # The VM name to remove, regex are supported
    [parameter(mandatory)]
    [String]$VMName,
    
    # A configuration setting to also delete public IP's, off by default
    $RemovePublicIP = $False
 )

    # Remove the VM's and then remove the datadisks, osdisk, NICs
    Get-AzureRmVM -ResourceGroupName $ResourceGroup | Where Name -Match $VMName  | foreach {
        $a=$_
        $DataDisks = @($a.StorageProfile.DataDisks.Name)
        $OSDisk = @($a.StorageProfile.OSDisk.Name) 

        if ($pscmdlet.ShouldProcess("$($_.Name)", "Removing VM, Disks, NIC (PublicIP): $($_.Name)"))
        {
            Write-Warning -Message "Removing VM: $($_.Name)"
            $_ | Remove-AzureRmVM -Force -Confirm:$false

            $_.NetworkProfile.NetworkInterfaces | where {$_.ID} | ForEach-Object {
                $NICName = Split-Path -Path $_.ID -leaf
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

            # Support to remove managed disks
            if($a.StorageProfile.OsDisk.ManagedDisk ) {
                ($OSDisk + $DataDisks) | where {$_.Name} | ForEach-Object {
                    Write-Warning -Message "Removing Disk: $_"
                    Get-AzureRmDisk -ResourceGroupName $ResourceGroup -DiskName $_ | Remove-AzureRmDisk -Force
                }
            }
            # Support to remove unmanaged disks (from Storage Account Blob)
            else {
                # This assumes that OSDISK and DATADisks are on the same blob storage account
                # Modify the function if that is not the case.
                $saname = ($a.StorageProfile.OsDisk.Vhd.Uri -split '\.' | Select -First 1) -split '//' |  Select -Last 1
                $sa = Get-AzureRmStorageAccount -ResourceGroupName $ResourceGroup -Name $saname
        
                # Remove DATA disks
                $a.StorageProfile.DataDisks | foreach {
                    $disk = $_.Vhd.Uri | Split-Path -Leaf
                    Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
                    Get-AzureStorageBlob -Blob  $disk |
                    Remove-AzureStorageBlob  
                }
        
                # Remove OSDisk disk
                $disk = $a.StorageProfile.OsDisk.Vhd.Uri | Split-Path -Leaf
                Get-AzureStorageContainer -Name vhds -Context $Sa.Context |
                Get-AzureStorageBlob -Blob  $disk |
                Remove-AzureStorageBlob  

            }
            
            # If you are on the network you can cleanup the Computer Account in AD            
            # Get-ADComputer -Identity $a.OSProfile.ComputerName | Remove-ADObject -Recursive -confirm:$false
        
        }#PSCmdlet(ShouldProcess)
    }

}