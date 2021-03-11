function Install-Module
{
    param (
        [string]$Name,
        [switch]$AllowPrerelease,
        [string]$RequiredVersion
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
    Import-Module -Name powershellget @Params -PassThru -MaximumVersion 2.2.5 -Prefix My
    $PSBoundParameters
    Install-MyModule @PSBoundParameters -Repository PSGallery -Force -Confirm:$false
}

function Uninstall-Module
{
    param (
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
    Import-Module -Name powershellget @Params -PassThru -MaximumVersion 2.2.5 -Prefix My
    $PSBoundParameters
    Uninstall-MyModule @PSBoundParameters
}