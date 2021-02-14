function Edit-Cmdlet {
param 
    (
        [String]$Cmdlet
    )

try {

        $Base = Get-Command -Name $Cmdlet -ErrorAction Stop  | 
                Select-Object Module | 
                ForEach-Object {
                    Get-Module $_.Module -ErrorAction Stop | 
                    Select-Object -ExpandProperty ModuleBase
                    }
        $Path = (Join-Path -Path $Base -ChildPath ($Cmdlet + ".*") -Resolve -ErrorAction Stop) 
        psedit -filenames $Path
    }
catch
    {
        "Cannot find that file, this is likely not a user written cmdlet"
    }

}#Edit-Cmdlet

