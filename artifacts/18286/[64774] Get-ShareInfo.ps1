<#
.Synopsis
   Query share information including connection numbers
.DESCRIPTION
   Returns the number of connections to Shares on local or remote systems and the share information
.EXAMPLE
   Get-ShareInfo -ComputerName Server1,Server2 | Format-Table -AutoSize
.EXAMPLE
   Get-ShareInfo -CN Localhost
.INPUTS
   A String or Array of ComputerNames
.OUTPUTS
   An OBJECT with the following properties is returned from this function
   PSComputerName,Name,Path,Description,Connections,MaximumAllowed,AllowMaximum
   You could check gwmi -class win32_Share | Get-Member and add extra properties if you like
.NOTES
   General
.FUNCTIONALITY
   Using WMI to query the number of open connections to Shares on local or remote systems
   Then adding this information to the basic win32_share info
#>
function Get-ShareInfo
{
    Param
    (
        # param1 help description
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   ValueFromRemainingArguments=$false, 
                   Position=0)]
        [Alias("cn")] 
        [String[]]$ComputerName
    )

    Begin
    {
    }
    Process
    {
        $ComputerName | ForEach-Object {
           $Computer = $_
           try {
                 # Connect to each computer and get the active connections on the shares
                 $Conns = Get-WmiObject -Class Win32_ConnectionShare -Namespace root\cimv2 -ComputerName $Computer -EA Stop | 
                    Group-Object Antecedent |
                    Select-Object @{Name="ComputerName";Expression={$Computer}},
                                  @{Name="Share"       ;Expression={(($_.Name -split "=") | 
                                        Select-Object -Index 1).trim('"')}},
                                  @{Name="Connections" ;Expression={$_.Count}}

                   # Connect to each computer and get the win32_share information (for all shares)
                   # Then add the connection details to those with connections.
                   try {
                            Get-WmiObject -Class Win32_Share -Namespace root\cimv2 -ComputerName $Computer -EA Stop |
                                ForEach-Object {
                                        $ShareInfo = $_
                                        $Conns | ForEach-Object {
                                            if ($_.Share -eq $ShareInfo.Name)
                                                {
                                                    $ShareInfo | Add-Member -MemberType NoteProperty -Name Connections -Value $_.Connections -Force
                                                }

                                            }#Foreach-Object($Conns) 

                                        if (!$ShareInfo.Connections)
                                            {
                                                $ShareInfo | Add-Member -MemberType NoteProperty -Name Connections -Value 0   
                                            }

                                        $ShareInfo | Select PSComputerName,Name,Path,Description,Connections,MaximumAllowed,AllowMaximum

                                    }#Foreach-Object(Share) 
                       }
                   catch
                       {
                            Write-Host "Cannot connect to $Computer" -BackgroundColor White -ForegroundColor Red
                            Break
                       }
               }
           catch 
               {
                    Write-Host "Cannot connect to $Computer" -BackgroundColor White -ForegroundColor Red
               }
                      

           }#ForEach-Object(Computer)
    }
    End
    {
    }
}