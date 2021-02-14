<#
.Synopsis
   Check remote eventlogs for tracking NTLM authentication delays and failures.
   Events will be available on Windows Server 2008 R2 with SP1 and KB2654097 installed.
   Events will be available on Windows Server Windows 7 with SP1 and KB2654097 installed.
   Events will be available on Windows Server 2012 and Windows 8.
.DESCRIPTION
   Event logs and details described in http://support.microsoft.com/kb/2654097
.EXAMPLE
   Get-MaxConcurrentAPIReport -ComputerName DC1,DC2
.EXAMPLE
   Get-MAXConcurrentAPIReport -ComputerName $env:COMPUTERNAME -DaysAgo 3 | ft -AutoSize
#>
function Get-MAXConcurrentAPIReport
{
    [CmdletBinding()]
    Param
    (
        # ComputerName - A String array (list) of computernames
        [Parameter(ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$ComputerName = $env:COMPUTERNAME,

        # Events - These are the associated Events
        [String[]]$Events = ("5816","5817","5818","5819"),
        #[String[]]$Events = ("36888","8017"),

        # LogName - The EventLogs to search
        [String[]]$LogName = "System",

        # DaysAgo - The number of days logs to retrieve
        [Int32]$DaysAgo = 0,

        # Starttime - Defaults to the same day, can provide a DateTime object.
        [DateTime]$StartTime = ([DateTime]::Today).AddDays(-$DaysAgo)
    )

    Begin
    {
        $FilterSearch = @{
            ID        = $Events
            LogName   = $LogName
            StartTime = $StartTime
        }
    }
    Process
    {
        $ComputerName | ForEach-Object {

          try {
                   Get-WinEvent -ComputerName $_ -FilterHashtable $FilterSearch -ErrorAction Stop |
                   Add-Member -MemberType NoteProperty -Name ComputerName -Value $_ -PassThru |
                   Select ComputerName,TimeCreated,ID,Message |
                   Sort TimeCreated
              }
          catch
              {
                   "No events of type: $Events" 
              }

        }#Foreach-Object(ComputerName)

    }
    End
    {
    }
}