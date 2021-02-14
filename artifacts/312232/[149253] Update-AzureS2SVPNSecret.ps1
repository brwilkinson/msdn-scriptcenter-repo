Function Update-AzureS2SVPNSecret {
  Param (
    [string]$LocalNetworkSiteName = 'Home',

    [String]$VNetName = 'VNETUS1'
  )

# make sure you are connected to your subscription.
#Set-AzureSM -SubscriptionName MSDN | Out-Null

$vnet = Get-AzureVNetGateway -VNetName $VNetName
$IP = $vnet.VIPAddress

# Get the VPN secret (Key value)
$key = Get-AzureVNetGatewayKey -VNetName $VNetName -LocalNetworkSiteName $LocalNetworkSiteName
$Secret = $key.Value

Invoke-command -cn RRAS -ScriptBlock {

    # set that on the RRAS server
    Get-VpnS2SInterface | where -Property ipv4subnet -match "10.0.1.0" | 
    Set-VpnS2SInterface -Destination $Using:IP -SharedSecret $Using:Secret -Force -Passthru |
    Select ConnectionState, Destination, AdminStatus, Name
}

# reconnect the S2S vpn link
Set-AzureVNetGateway -Connect -VNetName $VNetName -LocalNetworkSiteName $LocalNetworkSiteName
}