<#
.Synopsis
   Reboot a machine with BitLocker enabled, Disable Bitlocker first
.DESCRIPTION
   Allow you to reboot machine remotely with Bitlocker enabled, since this function disables it prior to rebooting.
   Bitlocker will be enabled after the reboot, however you will not be required to type in the pin for the single reboot.
   This script requires PSRemoting for the WSMAN and for the Restart-Computer.
.EXAMPLE
    PS PS:\> Restart-ComputerWithBitLocker -ComputerName Win8.Contoso.com -Force
    WARNING: Win8.Contoso.com: BitLocker disabled on C:

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Enable the Remote shutdown access rights and restart the computer." on
    target "Win8.Contoso.com".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"): y
.EXAMPLE
    PS PS:\> Restart-ComputerWithBitLocker
    WARNING: Computer123: BitLocker disabled on C:

    Confirm
    Are you sure you want to perform this action?
    Performing the operation "Enable the Local shutdown access rights and restart the computer." on
    target "localhost (Computer123)".
    [Y] Yes  [A] Yes to All  [N] No  [L] No to All  [S] Suspend  [?] Help (default is "Y"):
.FUNCTIONALITY
   http://msdn.microsoft.com/en-us/library/windows/desktop/aa376483(v=vs.85).aspx
#>
#requires -v 3.0
function Restart-ComputerWithBitLocker
{
  [CmdletBinding()]
  Param
  (
    # ComputerName of Machines to disable BDE
    [Parameter(ValueFromPipeline,
        ValueFromPipelineByPropertyName,
    Position=0)]
    [String[]]$ComputerName = $env:COMPUTERNAME,
    
    # Drive to disable BDE
    [Parameter(ValueFromPipelineByPropertyName,
    Position=1)]
    [String]$SystemDrive = 'C:',
    
    # Apply force to reboot a remote machine with someone logged on.
    [Switch]$Force
  )
  
  Begin
  {
    $CIM = @{
			Class       = 'Win32_EncryptableVolume'
			NameSpace   = 'root\CIMV2\Security\MicrosoftVolumeEncryption'
			Filter      = "DriveLetter='$SystemDrive'"
      ErrorAction = 'Stop'
  		}
    
  }
  Process
  {
    $CIM['ComputerName'] = $ComputerName
    try {
      # Where drive is FullyEncrypted
      Get-CimInstance @CIM | Where-Object ConversionStatus -EQ 1 | 
      Invoke-CimMethod -MethodName DisableKeyProtectors | 
      Where-Object -Property ReturnValue -eq 0 | ForEach-Object {
        
        Write-Warning -Message "$($_.PSComputerName): BitLocker disabled on $SystemDrive"
        
        #Now reboot
        if ($Force)
        {
          $Result = Restart-Computer -ComputerName $_.PSComputerName -Confirm -Force -AsJob
        }
        else
        {
          $Result = Restart-Computer -ComputerName $_.PSComputerName -Confirm -AsJob
        }
        
        # if confirm reboot
        if ($Result)
        {
          Write-Warning -Message "$($_.PSComputerName): Rebooting..."
          
          # Cleanup the job from the Restart-Computer
          Get-Job -Id $Result.id | Wait-Job | Remove-Job
        }
        else # Cancelled the reboot, renable BDE
        {
          Get-CimInstance @CIM | Where-Object ConversionStatus -EQ 1 | 
          Invoke-CimMethod -MethodName EnableKeyProtectors | ForEach-Object {
            
            if ($_.ReturnValue -eq 0)
            {
              Write-Warning -Message "$($_.PSComputerName): BitLocker protection resumed, restart cancelled by user.'"
            }
            else
            {
              Write-Warning -Message "$($_.PSComputerName): Rightclick on $SystemDrive to 'Resume BitLocker protection.'"
            }
            
          }#ForEach-Object(PSComputerName)Cancelled.
        }
      }#ForEach-Object(PSComputerName)
    }
    catch {
      Write-Warning -Message $_
    }        
  }
  
}#Restart-ComputerWithBitLocker