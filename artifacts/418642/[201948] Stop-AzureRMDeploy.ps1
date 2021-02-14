Function Stop-AzureRMDeploy
{
    Param(

        [parameter(mandatory)]
        [alias('DP')]
        [validateset('D1', 'D2', 'D3', 'D4', 'D5', 'D6', 'D7', 'D8', 'D9', 'P0', 'P1')]
        [string]$Deployment,

        [validateset('ADF','API')]
        [alias('App')]
        [string] $AppName = 'ADF',

        [validateset('AZC1','AZE2')]
        [alias('PF')]
        [string] $Prefix = 'AZC1',

        # Stop All deployments without confirmation or prompt
        [Switch]$Force
    )

    $ResourceGroupName = ($Prefix + '-' + $AppName + '-' + $Deployment)
    
    $Running = Get-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName | 
        where ProvisioningState -eq 'Running' | Select ProvisioningState,*Name,CorrelationId
        
    if ($Force)
    {
        $Running | ForEach-Object {

            Stop-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $_.DeploymentName
        }
    }
    else
    {
        $Running | Out-GridView -PassThru -Title 'Select Deployment/s to cancel . . .' | ForEach-Object {

            Stop-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -Name $_.DeploymentName
        }
    }
    
}