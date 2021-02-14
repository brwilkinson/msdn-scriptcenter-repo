##Requires -Module ActiveDirectory
##Requires -Module Azure
<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   New-VMBuildAzure -VMName DC10 -Subscription BRW -InstanceSize ExtraSmall
.EXAMPLE
   New-VMBuildAzure -VMName DC10 -Wait
.EXAMPLE
   New-VMBuildAzure -VMName PSWA101 -Subscription MSFT -BootStrapDSC
#>
function New-VMBuildAzure
{
    [CmdletBinding()]
    Param
    (
        # Choose the VirtualMachine Name
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [String[]]$VMName,

        # Choose the Instance Size of the Virtual Machine
        [ValidateSet('ExtraSmall','Small','Medium','Large')]
        [String]$InstanceSize = 'Small',

        # Choose the Subscription that you wish to add the VirtualMachine
        [ValidateSet('MSFT','BRW')]
        [String]$Subscription = 'MSFT',

        # Choose the Windows Image for the VirtualMachine
        [ValidateSet('Windows Server 2008 R2 SP1','Windows Server 2012 Datacenter',
                     'Windows Server 2012 R2 Datacenter','Windows Server Technical Preview')]
        [String]$WindowsImage = 'Windows Server 2012 R2 Datacenter',
        
        [String]$CertWildCardContosocom = 'yourcert*******************************',
        [String]$TimeZone = [System.TimeZoneInfo]::Local.Id,
        [String]$Domain = 'contoso.com',
        [String]$DomainAdminUser = 'administrator',
        [String]$AdminDomain = 'contoso',
        [String]$LocalAdminUser = 'myroot',
        [Switch]$BootStrapDSC,
        [Switch]$NoDomainJoin,
        [Switch]$Wait
    )

    Begin
    {
        $Cred = Get-Credential -Credential $AdminDomain\$DomainAdminUser
        Switch ($Subscription)
        {
            'MSFT' {
                        # this section is for you to connect to your azure subscription
                        # plus add your storage account, I use a custom function for this.
                        #$ServiceName = 'service123'
                        #$VNET = 'mynet123'
                        #Set-MyAzureSubscription -SubscriptionName MSFT
                    }
            'MSDN'  {
                        # this section is for you to connect to your azure subscription
                        # plus add your storage account, I use a custom function for this.
                        #$ServiceName = 'service456'
                        #$VNET = 'mynet123'
                        #Set-MyAzureSubscription -SubscriptionName MSDN 
                    }
        }#Switch

        $ProvisioningConfiguration = @{
            Windows         = $true
            AdminUsername   = $LocalAdminUser
            Password        = $Cred.GetNetworkCredential().Password
            TimeZone        = $TimeZone
            WinRMCertificate= (Get-ChildItem -Path Cert:\LocalMachine\My\$CertWildCardContosocom)
            }
        
        if (-not $NoDomainJoin)
        {
            $ProvisioningConfiguration.Remove('Windows')
            $ProvisioningConfiguration['WindowsDomain']   = $True
            $ProvisioningConfiguration['JoinDomain']      = $Domain
            $ProvisioningConfiguration['Domain']          = $Cred.GetNetworkCredential().Domain
            $ProvisioningConfiguration['DomainUserName']  = $Cred.GetNetworkCredential().UserName
            $ProvisioningConfiguration['DomainPassword']  = $Cred.GetNetworkCredential().Password
            $ProvisioningConfiguration['EnableWinRMHttp'] = $True
        }

        $MyImage = Get-AzureVMImage | Where-Object {$_.imagefamily -eq $WindowsImage} | 
            Sort-Object -Property PublishedDate | Select-Object -First 1

    }#Begin
    Process
    {
        $VMName | ForEach-Object {
            $VM = $_

            $MyVM = New-AzureVMConfig -Name $VM -InstanceSize $InstanceSize -ImageName $myImage.ImageName | 
                Add-AzureProvisioningConfig @ProvisioningConfiguration | 
                Set-AzureSubnet -SubnetNames 'Internal' |
                Add-AzureDataDisk -CreateNew -DiskSizeInGB 100 -DiskLabel 'DataDisk100' -LUN 0

            # Insert LCM configuration for PULL
            if ($BootStrapDSC)
            {
               $ADComputer = New-ADComputer -Name $VM -PassThru -Verbose
               
               $configurationArguments = @{
                  ComputerName    = $VM
                 }
               
               $DSCExtension = @{
                   # ConfigurationArgument: supported types for values include: primitive types, string, array and PSCredential
                   ConfigurationArgument = $configurationArguments
                   #ReferenceName         = 'AdminDesktop'
                   ConfigurationName     = 'AdminDesktop'
                   ConfigurationArchive  = 'AdminDesktop.ps1.zip'
                   Force                 = $True
                   Verbose               = $True
                  }

               $MyVM = $MyVM | Set-AzureVMDSCExtension @DSCExtension
               
            }#BootStrapDSC

            Write-Verbose -Message "Adding VM to $ServiceName" -Verbose
            try {
                $MyVM.ConfigurationSets
                $MyVM.ResourceExtensionReferences

                New-AzureVM –ServiceName $ServiceName –VMs $MyVM -ErrorAction Stop #-VNetName $VNET

                if (-not $Wait)
                {
                  $New = Get-AzureVM -Name $VM -ServiceName $ServiceName
                  $New
                  Write-Verbose -Message "Provisioning $VM this will take some time" -verbose
                  Write-Verbose -Message 'Run the following to get status update:' -Verbose
                  Write-Verbose -Message "Get-AzureVM -Name $VM -ServiceName $ServiceName" -verbose
                  [console]::Beep(15kb,400)
                  Continue
                }
                else{
            
                    do { 
                      $New = Get-AzureVM -Name $VM -ServiceName $ServiceName
                      $New
                      If ($BootStrapDSC)
                      {
                        $New.ResourceExtensionStatusList.Where{$_.HandlerName -eq 'Microsoft.Powershell.DSC'}.ExtensionSettingStatus.FormattedMessage
                      }
                      Write-Verbose -Message "Waiting for $VM : $(Get-Date)" -verbose
                      Start-Sleep -Seconds 20
                    } 
                    while ($New.Status -in 'Provisioning','RoleStateUnknown')
                }#Else
            }
            Catch {
                Write-Warning $_
            }
            [console]::Beep(15kb,400)
        }
    }#Process
}#New-VMBuildAzure