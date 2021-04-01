function Edit-Cmdlet
{
    param 
    (
        [String]$Cmdlet = 'Trace-AzureRMDSCExtension'
    )

    try
    {

        $Base = Get-Command -Name $Cmdlet -ErrorAction Stop -ov command |
            Select-Object Module |
            ForEach-Object {
                Get-Module $_.Module -ErrorAction Stop |
                    Select-Object -ExpandProperty ModuleBase
                }
        $Path = (Join-Path -Path $Base -ChildPath ($Command[0].Name + '.*') -Resolve -ErrorAction Stop) 
        if ($host.name -like '*ise*' -or $host.name -eq 'Visual Studio Code Host')
        {
            psEdit $Path
        }
        else
        {
            code $Path
        }
    }
    catch
    {
        'Cannot find that file, this is likely not a user written cmdlet'
    }
}#Edit-Cmdlet

