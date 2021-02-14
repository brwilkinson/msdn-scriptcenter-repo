<#
.Synopsis
    Retrieve the password from a SecureString or Credential
.DESCRIPTION
    Retrieve the password from a SecureString, Credential object or from a String,
    that has been created using the ConvertFrom-SecureString cmdlet.
.EXAMPLE
    PS C:\> $a = Read-Host -Prompt "Enter your password" -AsSecureString

    PS C:\> $a | Get-Password
    VERBOSE: SecureString
    Test
.EXAMPLE
    PS C:\> $a = Read-Host -Prompt "Enter your password" -AsSecureString

    PS C:\> Get-Password -SecureString $a
    VERBOSE: SecureString
    Test
.EXAMPLE
    PS C:\> $a = Read-Host -Prompt "Enter your password" -AsSecureString

    PS C:\> $a | ConvertFrom-SecureString | Set-Content -Path $home\Documents\TempPass.txt

    PS C:\> $c = Get-Content -Path $home\Documents\TempPass.txt

    PS C:\> $c | Get-Password
    VERBOSE: String
    Test
.EXAMPLE
    PS C:\> $a = Read-Host -Prompt "Enter your password" -AsSecureString

    PS C:\> $a | ConvertFrom-SecureString | Set-Content -Path $home\Documents\TempPass.txt

    PS C:\> $c = Get-Content -Path $home\Documents\TempPass.txt

    PS C:\> Get-Password -string $c
    VERBOSE: String
    Test 
.EXAMPLE
    PS C:\> $b = Get-Credential -Credential $env:USERDOMAIN\$env:USERNAME

    PS C:\> $b | Get-Password
    VERBOSE: Credential
    Test2
.EXAMPLE
    PS C:\> $b = Get-Credential -Credential $env:USERDOMAIN\$env:USERNAME

    PS C:\> Get-Password -Credential $b
    VERBOSE: Credential
    Test2
.EXAMPLE
    # This is a Powershell Version 3.0 + only feature
            
    PS C:\> $b = Get-Credential -Credential $env:USERDOMAIN\$env:USERNAME

    PS C:\> $b | Export-Clixml -Path $home\Documents\TempPass.xml

    PS C:\> $d = Import-Clixml -Path $home\Documents\TempPass.xml

    PS C:\> $d | Get-Password
    VERBOSE: Credential
    Test2
.INPUTS
    [String] -or [System.Management.Automation.PSCredential] -or [System.Security.SecureString]
.OUTPUTS
    [String]
.NOTES
    This is more of a concept script than anything else. Be aware of the security implications
    of storing passwords on disk.
.ROLE
    The role this cmdlet belongs to Test.
.FUNCTIONALITY
    Proof of concept script for Parameter sets and also securestring and credential conversions.
#>

function Get-Password {

       [CmdletBinding()]
       param (
              [String]$UserName = "XYZ",

              [Parameter(ParameterSetName='String',
                   Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
              [System.String]$String,

              [Parameter(ParameterSetName='SecureString',
                   Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
              [System.Security.SecureString]$SecureString,

              [Parameter(ParameterSetName='Credential',
                   Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
              [System.Management.Automation.PSCredential]$Credential

            )
       
       Write-Verbose $pscmdlet.ParameterSetName -Verbose

       if ($pscmdlet.ParameterSetName -eq "Credential")
       {
            $Credential.GetNetworkCredential().Password
       }
       else
       {
           if ($pscmdlet.ParameterSetName -eq "String")
           {
               $SecureString = ConvertTo-SecureString -String $String
           }        
            
            $PSCredentialType = 'System.Management.Automation.PSCredential'
            $Cred = New-Object $PSCredentialType -ArgumentList @($UserName, $SecureString)
            $Cred.GetNetworkCredential().Password
       }

}#Get-Password
