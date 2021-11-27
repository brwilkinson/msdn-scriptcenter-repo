function Edit-Cmdlet
{
    param 
    (
        [String]$Cmdlet = 'Trace-AzureRMDSCExtension'
    )

    try
    {

        $Base = Get-Command -Name $Cmdlet -ErrorAction Stop -ov command |
            ForEach-Object Module | Get-Module -ErrorAction Stop | ForEach-Object ModuleBase

        $ChildPath =switch ($Command[0].CommandType)
        {
            'Alias' {$command[0].ResolvedCommand.Name}
            Default {$command[0].Name}
        }

        $Path = (Join-Path -Path $Base -ChildPath ($ChildPath + '*.*') -Resolve -ErrorAction Stop)
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
        code foo.txt
    }
}#Edit-Cmdlet



