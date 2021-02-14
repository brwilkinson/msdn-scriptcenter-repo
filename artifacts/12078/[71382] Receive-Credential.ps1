function Receive-Credential {
[CmdletBinding(DefaultParameterSetName="Query")]
param ([parameter(Mandatory=$true,
                  ParameterSetName="Set")]
                  [switch]$set,
       [parameter(Mandatory=$true,
                  HelpMessage = "Please enter: Domain\Username",
                  ParameterSetName="Query",
                  Position=0)]
                  [String]$User
        )
if ($Set)
    {
        # Save your creds to disk, a hash in txt format.
        $Credential = Get-Credential -Credential $env:USERDOMAIN\$env:USERNAME -ErrorAction SilentlyContinue
        $FileName = $Credential.UserName -replace "\\","-"
        $FilePath = "$home\documents\$($FileName).txt"
        if ($FileName)
            {
                New-Item -Path $FilePath -ItemType File -Force -Verbose
                $credential.Password | ConvertFrom-SecureString | Set-Content $FilePath
            }
        else
            {
                Write-Verbose "Please supply credentials . . " -Verbose
            }
    }
else
    {
        # now if same user is logged on they can read the hash back in from disk
        $FileName = $User -replace "\\","-"
        $FilePath = "$home\documents\$($FileName).txt"
        if (Test-path $FilePath)
            {
                $password = Get-Content $FilePath | ConvertTo-SecureString 
                New-Object System.Management.Automation.PsCredential($user,$password)        
            }
        else
            {
                Write-Verbose "No file saved for user: $User. Please run: Receive-Credential -Set" -Verbose
            }
    }
}
