#requires -version 5.0
Function Test-UserCredential {
    param (
        [parameter(valuefrompipelinebypropertyname,valuefrompipeline)]
        [SecureString]$SecureStringPassword = (Read-Host -AsSecureString -Prompt EnterCurrentPassword),
        [parameter(valuefrompipelinebypropertyname)]
        [String]$Identity = $env:USERNAME,
        [parameter(valuefrompipelinebypropertyname)]
        [String]$UserDomain = $env:USERDNSDOMAIN
    )
    
    $cred = [pscredential]::new('temp',$SecureStringPassword)
    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ct = [DirectoryServices.AccountManagement.ContextType]::Domain
    try {
        $c = [System.DirectoryServices.AccountManagement.PrincipalContext]::new($ct,$UserDomain)
        $cto = [System.DirectoryServices.AccountManagement.ContextOptions]::Sealing
        $p = [DirectoryServices.AccountManagement.UserPrincipal]::FindByIdentity($c,$Identity)
        Write-Verbose -Message "Checking Password for $($p.DistinguishedName)" -Verbose
        $c.ValidateCredentials($p.UserPrincipalName,$cred.GetNetworkCredential().Password,$cto)
    }
    Catch {
        Write-Warning -Message $_
    }
    finally {
        Remove-Variable -Name SecureStringPassword
    }
}