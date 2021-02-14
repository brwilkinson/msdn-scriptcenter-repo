<#
.Synopsis
   Find AzureRM API Version based on the ProviderNameSpace and ResourceTypeName
.DESCRIPTION
   Find AzureRM API Version based on the ProviderNameSpace and ResourceTypeName
.EXAMPLE
    Find-AzureRMAPIVersion
.EXAMPLE
    Find-AzureRMAPIVersion -ProviderNamespace Microsoft.Compute
    2017-12-01
    2017-03-30
    2016-08-30
    2016-04-30-preview
    2016-03-30
    2015-06-15
    2015-05-01-preview
    WARNING: This provider: Microsoft.Compute/virtualMachines is available in the following regions:
    WARNING: East US, East US 2, West US, Central US, North Central US, South Central US, North Europe, West Europe, East Asia, Southeast Asia, Japan East, Japan West, Australia East, Australia Southeast, 
    Brazil South, South India, Central India, West India, Canada Central, Canada East, West US 2, West Central US, UK South, UK West, Korea Central, Korea South
.EXAMPLE
    Find-AzureRMAPIVersion -ProviderNamespace Microsoft.Compute -ResourceTypeName VirtualMachines
    2017-12-01
    2017-03-30
    2016-08-30
    2016-04-30-preview
    2016-03-30
    2015-06-15
    2015-05-01-preview
    WARNING: This provider: Microsoft.Compute/VirtualMachines is available in the following regions:
    WARNING: East US, East US 2, West US, Central US, North Central US, South Central US, North Europe, West Europe, East Asia, Southeast Asia, Japan East, Japan West, Australia East, Australia Southeast, 
    Brazil South, South India, Central India, West India, Canada Central, Canada East, West US 2, West Central US, UK South, UK West, Korea Central, Korea South    
#>

Function Find-AzureRMAPIVersion {

param (
   $ProviderNamespace,
   
   $ResourceTypeName
)

try {
    if (! $ProviderNamespace)
    {
        $ProviderNamespace = Get-AzureRmResourceProvider | Out-GridView -OutputMode Single -Title "Select the ProviderNamespace? Then click OK." | Foreach ProviderNamespace
    }
    if (! $ResourceTypeName)
    {
        $ResourceTypeName = (Get-AzureRmResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop).ResourceTypes |
            Out-GridView -OutputMode Single -Title "Select the ResourceTypeName? Then click OK." | Foreach ResourceTypeName
    }

    $Provider = (Get-AzureRmResourceProvider -ProviderNamespace $ProviderNamespace -ErrorAction Stop).ResourceTypes | Where-Object ResourceTypeName -eq $ResourceTypeName
    
    if ($Provider)
    {
        ($provider).ApiVersions
        Write-Warning -Message "This provider: $ProviderNamespace/$ResourceTypeName is available in the following regions:"
        Write-Warning -Message ($Provider.Locations -join ', ')
    }
    else
    {
        Throw "ResourceTypeName: '$ResourceTypeName' is invalid"
    }
   }
   Catch {
    Switch -Regex ( $_ )
    {
        Default {Write-Warning -Message $_}
    }
   }
}