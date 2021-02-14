function Trace-AzureRMDSCExtension
{
    Param (
        [String]$ResourceGroup,

        # The VM name, regex are supported
        [String]$VMName,
        
        [validateset('Microsoft.Powershell.DSC', 'Microsoft.Powershell.DSC.Pull', 'Microsoft.Powershell.DSC.Push')]
        [String]$ExtensionName = 'Microsoft.Powershell.DSC',
        
        [Int]$LoopTime = 10,

        [Int]$StatusView = 1
    )    

    while ($true)
    { 
        Get-AzureRmVM -ResourceGroupName $ResourceGroup -Status | Where Name -Match $VMName  | foreach {
        Get-AzureRmVMExtension -ResourceGroupName $ResourceGroup -Name  $ExtensionName -VMName $_.Name -Status -ErrorAction silentlycontinue | 
            foreach substatuses | select -first $StatusView   ; sleep $LoopTime
        }
    }

}