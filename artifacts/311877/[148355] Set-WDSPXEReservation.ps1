Function Set-WDSPXEReservation {
[cmdletbinding()]
param (
        $WDSServer = 'wds.contoso.com',
        $ComputerName = 'TempDeploy',

        [parameter(Mandatory)]
        $MacAddress    
        )

    # PXE is default, need to approve on WDS Server
    # Need to setup a contrained endpoint with a runas account to get around the double hop
    # to write to AD on the computer account from the WDS server
    $PSS = New-PSSession -ComputerName $WDSServer -ConfigurationName WDS
    try {                     
            Invoke-Command -Session $PSS -ScriptBlock {
                        
                  Import-Module -Name WDS -Force -Scope Local

                    # can only deploy 1 machine at the moment, since only 1 temp account in AD
                    # have to add more computer accounts to set the reservation on in WDS
                    # you can also create the computer account here using the actual computername
                    # instead of the tempdeploy computer account.
                    $TempComputerName = ($Using:ComputerName) # + '_' + (Get-Date | foreach Ticks))

                    $Params = @{
                        DeviceName      = $TempComputerName 
                        DeviceID        = $Using:MacAddress
                        PxePromptPolicy = 'NoPrompt'
                        #JoinDomain      = $False
                        Erroraction      = 'Stop'
                       }
                    
                    Write-Verbose -Message ([pscustomobject]$Params) -Verbose

                    try {
                        Write-Verbose "Setting WDS PXE reservation: $Using:MacAddress" -Verbose
                       # The set-wdsclient wo
                       Restart-Service -Name Winmgmt -force -PassThru -Verbose
                       $Result = WDS\Set-WdsClient @Params | select DeviceName,DeviceID,BootImagePath

                    $Result
                    }#Try
                    catch
                    {
                        $_ | select *
                    }#Catch
            }#ICM
        }#try
        catch {
            $_ | select *
        }#Catch
        finally {
            $PSS | Remove-PSSession
        }#Finally
}#Set-WDSPXEReservation