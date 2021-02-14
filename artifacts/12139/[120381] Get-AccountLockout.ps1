function global:Get-AccountLockout {
     
     #Requires -Version 2.0
     [CmdletBinding()]
     Param (
          [Parameter(ValueFromPipeline=$true,
                     ValueFromPipelineByPropertyName=$true)]
          [String]$Account = $env:USERNAME,
          $HomeDir = "C:\PS\AccountLockout",
          $LogDir = "$HomeDir\Logs",
          $EventID = "529 644 675 676 681",
          [Switch]$FullLog
     )#End Param
     
     # Get-BadPasswordInfo can be downloaded here:
     # http://gallery.technet.microsoft.com/scriptcenter/Find-the-Bad-Password-c207d807
     $DC1,$DC2,$DC3 = (Get-BadPasswordInfo -User $Account)[0..2] | 
     ForEach-Object {($_.DomainController -split "\.")[0]}    
     
     $Option -= 1
     $Servers = $DC1 + ", " + $DC2 # + ", " + $DC3
     $LogName1 = "$LogDir\$DC1-Security_LOG.txt"
     $LogName2 = "$LogDir\$DC2-Security_LOG.txt"
     #$LogName3 = "$LogDir\$DC3-Security_LOG.txt"
     
     # Call the eventcombMT.exe to parse the logs on the chosen server, 
     # this presents in the GUI, however does not need user input.
     "Checking DCs: $Servers for bad password events . . "
     
     # Run eventcombMT and then wait until it finishes.
     # Note the 3rd DC is currently commented out below
     & "$Homedir\Tools\eventcombMT.exe" /s:$DC1 /s:$DC2 /et:safa /log:sec /text:$Account /outdir:$LogDir /evt:$EventID /t:75 /start # /s:$DC3
     Get-Process -Name eventcombMT -ErrorAction SilentlyContinue | Wait-Process
     
     # After the process finished running the required information will be in the log file
     # We can now parse the logfile to view the offending device ID
     
     if (!($FullLog))
     {
          if ((Test-Path $LogName1) -or (Test-Path $LogName2) -or (Test-Path  $LogName3))
          {
               if (Test-Path $LogName1)
               {
                    
                    get-content $LogName1 | ForEach-Object {$_} | Where-Object {$_ -match "AUDIT FAILURE"} |
                    Foreach {$_.Split(",")[5]} | ForEach-Object {[regex]::split($_, "\s\s\s\s\s")} |
                    ForEach-Object {$_} | 
                    Where-Object {(($_ -match "\\") -or ($_ -match "Client Address:*") -or ($_ -match "User Name:"))}
               }
               if (Test-Path $LogName2)
               {
                    get-content $LogName2 | ForEach-Object {$_} | Where-Object {$_ -match "AUDIT FAILURE"} |
                    Foreach {$_.Split(",")[5]} | ForEach-Object {[regex]::split($_, "\s\s\s\s\s")} |
                    ForEach-Object {$_} | 
                    Where-Object {(($_ -match "\\") -or ($_ -match "Client Address:*") -or ($_ -match "User Name:"))}
               }
               if (Test-Path $LogName3)
               {
                    get-content $LogName3 | ForEach-Object {$_} | Where-Object {$_ -match "AUDIT FAILURE"} |
                    Foreach {$_.Split(",")[5]} | ForEach-Object {[regex]::split($_, "\s\s\s\s\s")} |
                    ForEach-Object {$_} | 
                    Where-Object {(($_ -match "\\") -or ($_ -match "Client Address:*") -or ($_ -match "User Name:"))}
               }
          }
          else 
          {
               write-host "No event logs found matching your selection" -BackgroundColor red
          }
     }
     else
     {
          get-content $LogName1 -EA 0
          get-content $LogName2 -EA 0
          get-content $LogName3 -EA 0
     }
     
}