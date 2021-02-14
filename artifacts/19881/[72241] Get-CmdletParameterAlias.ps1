function Get-CmdletParameterAlias {
param (
        [parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [alias("Name")]
        [String[]]$Cmdlet,
        [Switch]$ExcludeCommon
        )
Begin {
       $Common = "Verbose","Debug","ErrorAction","WarningAction","ErrorVariable","WarningVariable","OutVariable","OutBuffer","WhatIf","Confirm"
}#begin

Process {
try {
    Get-Command -Name $cmdlet -ErrorAction Stop |  ForEach-Object { 
        $CmdletName = $_.Name
        $_.Parameters.Values | where {$_.Aliases} | ForEach-Object {
        if ($ExcludeCommon)
            {
                If (-not ($Common -contains $_.Name))
                    {
                        $_ | Add-Member -MemberType noteproperty -Value $CmdletName -Name Cmdlet -Force -PassThru | 
                        Select-Object cmdlet,name, aliases
                    }
            }
        Else 
            {
                $_ | Add-Member -MemberType noteproperty -Value $CmdletName -Name Cmdlet -Force -PassThru | 
                Select-Object cmdlet,name, aliases
            }         
        }#Foreach-Object(Alias)
    }#Foreach-Object(Cmdlet)
}#try
catch {
    "`nPlease enter a valid cmdlet name, `"$Cmdlet`" not recognized"
}#catch
}#process
}#Get-CmdletParameterAlias

