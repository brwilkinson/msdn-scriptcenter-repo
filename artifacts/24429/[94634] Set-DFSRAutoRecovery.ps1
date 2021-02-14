function Set-DFSRAutoRecovery {
param (
        [String[]]$ComputerName = $env:COMPUTERNAME,
        [Switch]$Enabled
        )

$ComputerName | ForEach-Object {
    $Computer = $_

    Try {
    
        $DFSR = Get-Service -Name DFSR -ComputerName $_ -ErrorAction Stop
    
        # open remote registry key
        $HKLM = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine”, $Computer)

        # get subkey via method
        $HKLMSubkey = $HKLM.OpenSubKey("System\CurrentControlSet\Services\DFSR\Parameters", $true)

        # get value names
        $AutoRecovery = $HKLMSubkey.GetValue("StopReplicationOnAutoRecovery")

        If ($AutoRecovery -eq 1 -AND $Enabled)
        {
            $HKLMSubkey.setvalue("StopReplicationOnAutoRecovery", "0", "Dword")
            
            $hash = @{
            ComputerName = $_.ToUpper()
            OldSetting = $AutoRecovery
            NewSetting = 0
            Message = "DFSR automatic recovery is now enabled"
            DFSRStatus = $DFSR.Status
            }
        }
        elseIf ($AutoRecovery -eq 1 -AND $Enabled -eq $False)
        {
            $hash = @{
            ComputerName = $_.ToUpper()
            OldSetting = $AutoRecovery
            NewSetting = 1
            Message = "DFSR automatic recovery is still disabled"
            DFSRStatus = $DFSR.Status
            }
        }
        elseif ($AutoRecovery -eq 0 -AND $Enabled)
        {
            $hash = @{
            ComputerName = $_.ToUpper()
            OldSetting = $AutoRecovery
            NewSetting = 0
            Message = "DFSR automatic recovery is still enabled"
            DFSRStatus = $DFSR.Status
            }
        }
        elseif ($AutoRecovery -eq 0  -AND $Enabled -eq $False)
        {
            
            $HKLMSubkey.setvalue("StopReplicationOnAutoRecovery", "1", "Dword")
            
            $hash = @{
            ComputerName = $_.ToUpper()
            OldSetting = $AutoRecovery
            NewSetting = 1
            Message = "DFSR automatic recovery is now disabled"
            DFSRStatus = $DFSR.Status
            }
        }
        else
        {
            $HKLMSubkey.CreateSubKey("StopReplicationOnAutoRecovery")
            $HKLMSubkey.setvalue("StopReplicationOnAutoRecovery", "0", "Dword")
            
            $hash = @{
            ComputerName = $_.ToUpper()
            OldSetting = "SubKey Not Present"
            NewSetting = 0
            Message = "DFSR automatic recovery is still enabled, created subkey"
            DFSRStatus = $DFSR.Status
            }
        }

        New-Object psobject -Property $hash | Select ComputerName,Message,DFSRStatus,OldSetting,NewSetting

    }
    Catch {

        Write-Verbose "DFSR Service not present on $Computer" -Verbose
    }


    }

}