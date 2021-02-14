function global:Get-Uptime {

#Requires -Version 2.0
[CmdletBinding(DefaultParametersetName="ComputerName")]
 Param 
   (
    [Parameter(Mandatory=$true,
               Position=1,
               ParameterSetName="ComputerName",   
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [String[]]$ComputerName,
    [Switch]$Text,
    [Switch]$Summary
   )#End Param 

Begin
{
 Write-Verbose "Retrieving Uptime Info . . ." -Verbose
 $ErrPref = $ErrorActionPreference
}
Process
{

 $UptimeReport = $ComputerName | ForEach-Object {
 $Server = $_
 try{
    $ErrorActionPreference = "Stop"
    $wmi=Get-WmiObject -class Win32_OperatingSystem -computer $_

    if ($wmi -ne $Null)
        {
            $LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
            [TimeSpan]$uptime=New-TimeSpan $LBTime $(get-date)
            New-Object PSObject -Property @{ 
            Server=$_
            Uptime="----->"
            Days=$uptime.days
            Hours=$uptime.hours
            Minutes=$uptime.minutes
            Seconds=$uptime.seconds
            }
        }
    $wmi=$null
    $ErrorActionPreference = $ErrPref
}
catch {
        "Cannot connect to wmi on $Server"
        $ErrorActionPreference = $ErrPref
    }

}#Foreach-Object($Server)

if ($Text)
    {
        Get-Date | Out-Host
        $UptimeReport | Select-Object Server,Uptime,Days,hours,minutes,seconds |
        Sort-Object Days -Descending | Format-Table -AutoSize
    }
elseif ($Summary)
    {
        Get-Date | Out-Host
        $UptimeReport | Select-Object Server,Uptime,Days | 
        Sort-Object -Property Days -Descending 
    }
else
    {
        Get-Date | Out-Host
        $UptimeReport | Select-Object Server,Uptime,Days,hours,minutes,seconds |
        Sort-Object -Property Days -Descending
    }

}#Process
}#Get-Uptime
