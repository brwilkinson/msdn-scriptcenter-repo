Function Remove-AzureRMVMExtensionParallel {
[cmdletbinding()]
 Param (
    [parameter(mandatory)]
    [String]$ResourceGroup,
    
    # The VM name to remove, regex are supported
    [parameter(mandatory)]
    [String]$VMName,

    # The Name/Type of Extension to remove, NB, these are user defined, so you need to update this list
    [validateset('DependencyAgent','Microsoft.Powershell.DSC','MonitoringAgent')]
    [String]$Extension,

    # The Script will not wait for the background jobs by default, use this switch to wait
    [Switch]$Wait,

    # Query the extension only, do not delete
    [Switch]$Query
 )

    # Remove the VM extension, that you specify, 
$jobs = Get-AzureRmVM -ResourceGroupName $ResourceGroup -Status | Where Name -Match $VMName  | foreach {
        $vm=$_
        
        # avoid locks on the tokencache.dat file
        Start-Sleep -Seconds 3
        
        Start-Job -ScriptBlock {
            
            Try {
                $ctx = Import-AzureRmContext -path d:\ctx.json -ErrorAction Stop
                $resourceGroup = $using:Resourcegroup
                $VMName = $using:VM
                #$ctx
                #Get-AzureRmResourceGroup -Name $resourceGroup

                Write-Verbose -Message "Connected to $($ctx.Context.Subscription.Name)" -Verbose

                if ($Using:Query)
                {
                    Get-AzureRmVMExtension -ResourceGroupName $ResourceGroup -VMName $VMName.name -Name $using:Extension -Status -ea Ignore |
                        select VMName,Name,ProvisioningState,@{n='extensionsstatus';e={$_.statuses.message}} | ft -AutoSize
                }
                else
                {
                    Remove-AzureRmVMExtension -ResourceGroupName $resourceGroup -VMName $VMName.name -Name $using:Extension -force -verbose
                }
            }
            Catch {
                Write-Warning -Message 'You must save your Context first [Save-AzureRmContext -Path D:\ctx.json -Force]'
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