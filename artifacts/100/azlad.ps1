#requires -Modules AzureAdPreview 
#requires -PSEdition Desktop

function azlad
{
    param (
        [switch]$Force
    )

    $Params = @{
        WarningAction = 'SilentlyContinue'
    }
    
    if ($PSVersionTable.PSVersion.Major -ne 5)
    {
        $Params['UseWindowsPowerShell'] = $true
    }
    Import-Module -Name AzureAdPreview @params

    try
    {
        $id = Get-AzContext
    
        if ($Force)
        {
            # $x = [System.Exception]::new('Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException')
            throw forceLogin
        }
    
        $CurrentSession = Get-AzureADCurrentSessionInfo -ErrorAction stop
        Write-Host -ForegroundColor Yellow 'Already logged into Azure AD'
        $CurrentSession
    }
    catch #[Microsoft.Open.Azure.AD.CommonLibrary.AadNeedAuthenticationException]
    {
        Write-Host -ForegroundColor Yellow 'Logging into Azure AD'
        Connect-AzureAD -AccountId $id.account.id -TenantId $id.Tenant.Id
    }
}