<#
.Synopsis
   List WSMAN Sessions
.DESCRIPTION
   List WSMAN Sessions on local or remote machines
.EXAMPLE
   Get-WSMANSession
.EXAMPLE
   Get-WSMANSession -ComputerName server123

#>
function Get-WSMANSession
{
    [CmdletBinding()]
    Param
    (
        # ComputerName to query WSMAN session
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)]
        [Alias('CN')] 
        [String[]]$ComputerName =  $env:COMPUTERNAME,

        # Credential to Connect to ComputerName
        [System.Management.Automation.PSCredential]$Credential,

        # The name of the Custom Format Type for the Output
        [String]$CustomType = 'My.Custom.WSMAN',

        # Items are used for Custom Output via Format File
        [string[]]$Items = ('Name','Owner','State','MemoryUsed','ClientIP','ShellRunTime','ShellInactivity','ProcessId')
    )

begin {

        $Params = @{
            ResourceURI   = 'shell'
            Enumerate     =  $true
            }

        if ($PSBoundParameters.ContainsKey("Credential"))
        {
            $Params['Credential'] = $credential
        }

        Function UpdateTimeSpan {
        param (
            [String]$TS
            )
            $regex = "(P)(?<Days>\d+)(D)(T)(?<Hours>\d+)(H)(?<Minutes>\d+)(M)(?<Seconds>\d+)(S)"
            $null = $TS -match $regex
            $TimeSpan = New-TimeSpan -Days $Matches.Days -Hours $Matches.Hours -Minutes $Matches.Minutes -Seconds $Matches.Seconds
            $TimeSpan.ToString()
        }
    

#region Define Custom XML Format based on Items.
$Header = @"
<?xml version="1.0" encoding="utf-8" ?> 
<Configuration>
    <ViewDefinitions>
       <View>
            <Name>$CustomType</Name>
            <ViewSelectedBy>
                <TypeName>$CustomType</TypeName>
            </ViewSelectedBy>
            <TableControl>
                <TableHeaders>
"@

$columnHeaders = $Items | ForEach-Object {
@"
                    <TableColumnHeader>
                        <Label>$_</Label>
                        <Width>20</Width>
                        <Alignment>Left</Alignment>
                    </TableColumnHeader>

"@
}

$Mid = @"
                </TableHeaders>
                <TableRowEntries>
                    <TableRowEntry>
                        <TableColumnItems>

"@

$columnItems = $items | ForEach-Object {
@"
                            <TableColumnItem>
                                <PropertyName>$_</PropertyName>
                            </TableColumnItem>

"@
}

$End = @"
                        </TableColumnItems>
                    </TableRowEntry>
                </TableRowEntries>
            </TableControl>
        </View>
    </ViewDefinitions>
</Configuration>
"@
#endregion

#region Put the Custom Format XML together, export to file & then import.
    $Format = $Header + $columnHeaders + $Mid + $columnItems + $End
    
    if (! (Get-FormatData -TypeName $CustomType))
    {
        $FormatPath = Join-Path -Path $env:TEMP -ChildPath "$CustomType.ps1xml"
        Set-Content -Path $FormatPath -Value $Format
        Update-FormatData -AppendPath $FormatPath
        #Remove-Item -Path $FormatPath
    }
#endregion

}

Process {

    $ComputerName | ForEach-Object {

    $Params['ConnectionURI'] = ("http://{0}:5985/wsman" -f $_)
    $Params['ComputerName']  = ($_) 

    try {
        Get-WSManInstance @Params | 
            ForEach-Object { 
                $_.ShellRunTime = UpdateTimeSpan -TS $_.ShellRunTime
                $_.ShellInactivity = UpdateTimeSpan -TS $_.ShellInactivity
                $_
            } |    
            ForEach-Object { $_.pstypenames.insert(0,$CustomType) ; $_ }
    }
    Catch {
        Write-Warning $_
    }

    }
}#Process
}#Get-WSMANSession

 