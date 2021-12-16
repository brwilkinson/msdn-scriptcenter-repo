function Publish-ProxyFunction {

param (
        [String]$Cmdlet,
        $FilePath = ([System.IO.Path]::GetTempFileName() -replace '.tmp$','.ps1')

        )

Begin           
{   
    Set-StrictMode -Version 2.0

    # Create the proxy function metadata
    $Metadata = New-Object System.Management.Automation.CommandMetaData (Get-Command $Cmdlet)
    $NewMeta = [System.Management.Automation.ProxyCommand]::Create($Metadata)
    
    # Add the function with comments
    $Header =  "function $Cmdlet" + "_proxy {`n"
    $Trailor = "`n}#$Cmdlet" + "_proxy"

    # Output the data to the temp file and open it up.
    ($Header + $NewMeta + $Trailor) | Out-File $FilePath
    psEdit $FilePath

}#Begin


}#Publish-ProxyFunction
