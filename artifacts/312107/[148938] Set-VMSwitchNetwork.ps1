<# contents of CSV with IP settings for the vswitches
Name     IPAddress   DNSServer   DefaultGateway
----     ---------   ---------   --------------
PSV4     10.0.1.50   10.0.1.200                
Internal 10.10.10.50 10.10.10.10               
NAT      172.10.0.1
#>

function Set-VMSwitchNetwork {
	Param (
		$VMSwitchConfigPath = "PS:\VMSwitch\VM-Switch-$env:COMPUTERNAME.txt",
		$Slash = 24
	)

	Get-Module -Name hyper-v | Remove-Module
	Import-Module -Name hyper-v -RequiredVersion 1.1
    
    # disconnect all switches from VM's
    Get-VM | Get-VMNetworkAdapter | Disconnect-VMNetworkAdapter
    
    # remove all of the Switches
    'PSV4','Internal','NAT-172-10-0_24' | foreach-object {
    Get-VMSwitch -name $_ | Remove-VMSwitch -Verbose -Confirm:$False -Force -EA 0
    }

    # Create new switches
    sleep -Seconds 5
    New-VMSwitch -Name PSV4 -SwitchType Internal -Verbose
    New-VMSwitch -Name Internal -SwitchType Internal -Verbose
    #New-VMSwitch -Name Internet-Bridge -NetAdapterName Wi-Fi

    Get-Module -Name hyper-v | Remove-Module
    Get-NetNat | Remove-NetNat -Confirm:$false
    New-VMSwitch -Name NAT-172-10-0_24 -SwitchType NAT -NATSubnetAddress "172.10.10.0/24"


	Get-Module -Name hyper-v | Remove-Module
	Import-Module -Name hyper-v -RequiredVersion 1.1

	Import-Csv -Path (Resolve-Path -Path $VMSwitchConfigPath) | ForEach-Object {
			$NIC = $_ 	
            $Current = '*' + $Nic.Name + '*'
            $IP = $_.IPAddress
            $DNSServer = $_.DNSServer
            $Name = Get-NetAdapter -Name $Current | Foreach Name 
		try {

            # Don't bridge any adapters anymore, use NAt instead
            #if ($Nic.SwitchType -eq 'External')
            #{
            #    Get-NetAdapter -InterfaceAlias wi-fi | Set-VMSwitch -Name $Nic.Name
            #}

			$IFIndex = Get-NetIPConfiguration -InterfaceAlias $Name | Foreach InterfaceIndex
			if ($IFIndex -and $Nic.IPAddress)
			{
				Enable-NetAdapter -InterfaceAlias $Name -Confirm:$False

                Set-NetIPInterface –InterfaceIndex $IFIndex -Dhcp Enabled

                Get-NetIPAddress -InterfaceIndex $IFIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue | 
                    Remove-NetIPAddress -Confirm:$False -ErrorAction SilentlyContinue

                New-NetIPAddress –IPAddress $IP –PrefixLength $Slash -InterfaceIndex $IFIndex -AddressFamily IPv4

				Set-DnsClientServerAddress -InterfaceIndex $IFIndex -ServerAddresses $DNSServer -PassThru
                
                Disable-NetAdapter -InterfaceAlias $Current -Confirm:$False
                Enable-NetAdapter -InterfaceAlias $Current -Confirm:$False

			}
			else
			{
				"Cannnot find InterfaceAlias: $IFAlias"
			}
		}#Try
		Catch {
			Write-Warning $_
		}#Catch
	}#Foreach-object(VMSwitch)
    
    
    # Reconnect the VM to the new switch based on the wildcard name of the VM
    Connect-VMNetworkAdapter -Verbose –SwitchName Internal -VMName PSDSC*
    Connect-VMNetworkAdapter -Verbose –SwitchName PSV4 -VMName *V4*
    Connect-VMNetworkAdapter -Verbose –SwitchName NAT-172-10-0_24 -VMName *Nano*,*CentOS*

    New-NetNat -Name NAT -InternalIPInterfaceAddressPrefix "172.10.0.0/24"

    $all = Get-VMNetworkAdapter -VMName *mygateway*
    $all[0] | Connect-VMNetworkAdapter -SwitchName NAT-172-10-0_24 -Passthru
    $all[1] | Connect-VMNetworkAdapter -SwitchName psv4 -Passthru
    $all[2] | Connect-VMNetworkAdapter -SwitchName Internal -Passthru
    
    # Set the metric on the interface, which is essentially the binding order.
    #Get-NetIPInterface -ifAlias *bridge* | Set-NetIPInterface -InterfaceMetric 15
    Get-NetIPInterface -ifAlias *Internal* | Set-NetIPInterface -InterfaceMetric 50
    Get-NetIPInterface -ifAlias *PSV4* | Set-NetIPInterface -InterfaceMetric 75
    Get-NetIPInterface -ifAlias *Nat* | Set-NetIPInterface -InterfaceMetric 75

}#Set-VMSwitchNetwork