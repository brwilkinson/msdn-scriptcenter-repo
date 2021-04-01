function Install-Module
{
    [cmdletbinding()]
    param (
        [parameter(Mandatory, Position = 0)]
        [string]$Name,
        [switch]$AllowPrerelease,
        [string]$RequiredVersion,
        [validateset('CurrentUser', 'AllUsers')]
        [string]$Scope
    )

    Remove-Module -Name PowerShellGet -EA Ignore
    $Params = if ($PSVersionTable.PSVersion.Major -le 5)
    {
        @{}
    }
    else 
    {
        @{
            UseWindowsPowerShell = $true
        }
    }
    Import-Module -Name powershellget @Params -PassThru -MaximumVersion 2.2.5 -Prefix My -EA Ignore
    $PSBoundParameters
    
    # gcm Install-MyModule -syntax
    Install-MyModule -Repository PSGallery -Force -AllowClobber -Confirm:$false @PSBoundParameters

    Get-Module -Name $Name -ListAvailable -All | Select-Object Name, Path, Version
}

function Uninstall-Module
{
    [cmdletbinding()]
    param (
        [parameter(Mandatory, Position = 0)]
        [string]$Name
    )

    $env:PSModulePath = 'C:\Program Files\WindowsPowerShell\Modules'
    Remove-Module -Name PowerShellGet -EA Ignore
    $Params = if ($PSVersionTable.PSVersion.Major -le 5)
    {
        @{}
    }
    else 
    {
        @{
            UseWindowsPowerShell = $true
        }
    }
    Import-Module -Name powershellget @Params -PassThru -MaximumVersion 2.2.5 -Prefix My -EA Ignore
    $PSBoundParameters
    Uninstall-MyModule @PSBoundParameters

    Get-Module -Name $Name -ListAvailable -All | Select-Object Name, Path, Version
}