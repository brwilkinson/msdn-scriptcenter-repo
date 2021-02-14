function Global:Get-VolumeWin32 {
      
      #Requires -Version 2.0
      [CmdletBinding()]
      Param (
            [Parameter(Position=1,
                       ValueFromPipeline=$true,
                       ValueFromPipelineByPropertyName=$true)]
            [String[]]$ComputerName = $env:COMPUTERNAME
      )#End Param
      Begin
      {
            $Query = "Select SystemName,Name,VolumeName,Size,DriveType,FreeSpace from Win32_LogicalDisk WHERE DriveType = '3'"
            $NameSpace = "root\cimv2"
            Write-Verbose "Retrieving Volume Info . . ."
            Write-Verbose $Query
            Write-Verbose "from NameSpace: $NameSpace `n"
      }
      Process
      {
            
            $ComputerName | foreach-object {
                  $Computer = $_
                  Write-Verbose "Connecting to:--> $Computer"
                  
                  try {
                        Get-WmiObject -Query $Query -Namespace $NameSpace -ComputerName $Computer -ErrorAction Stop |
                        Where-Object {$_.name -notmatch "\\\\" -and $_.DriveType -eq "3"} |
                        ForEach-Object {$RAW = $_ | Select-Object -Property SystemName,Name,VolumeName,Size,FreeSpace ; Write-Verbose $RAW ; $_ } |
                        Select-Object SystemName, Name, VolumeName,
                        @{name="CapacityGB";Expression={"{0:N2}"  -f ($_.size / 1gb)}},
                        @{name="UsedGB";Expression={"{0:N2}"  -f ($($_.size-$_.freespace) / 1gb)}},
                        @{name="FreeGB";Expression={"{0:N2}"  -f ($_.freespace / 1gb)}},
                        @{name="FreePC";Expression={"{0:N2}"  -f ($_.freespace / $_.size * 100)}} | Sort-Object SystemName,Name 
                  }
                  Catch {
                        Write-Warning "$Computer : $_"
                  }
            }#Foreach-Object(ComputerName)
      } 
      
}#Get-VolumeWin32
