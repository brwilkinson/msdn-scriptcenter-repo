Function Update-AzureS2SVPNEndpoint {
  Param (
    $LocalNetworkSiteName = 'RemoteNYC',
    $Root = 'c:\scripts\azure',
    $CurrentConfig = "$Root\AzureVNetConfig.txt",
    $NewConfig =  "$Root\AzureVNetConfigNew.txt"
  )
  
  [string]$CurrentWANIP = Get-WANIPAddress | Select-Object -ExpandProperty WANIPAddress
  
  try {
    
    [xml]$XML = Get-AzureVNetConfig -ExportToFile $CurrentConfig -ErrorAction Stop | 
    Select-Object -ExpandProperty XMLConfiguration
    
    # to do validate document
    
    $LocalNetworkSite = $XML.NetworkConfiguration.VirtualNetworkConfiguration.LocalNetworkSites.LocalNetworkSite | 
      Where-Object Name -EQ $LocalNetworkSiteName
    
    if ($LocalNetworkSite.VPNGatewayAddress -ne $CurrentWANIP)
    {
      Write-Warning -Message ( "Updating $LocalNetworkSiteName S2SVPN GW to $CurrentWANIP $(Get-Date)" )
      $LocalNetworkSite.VPNGatewayAddress = $CurrentWANIP
      $XML.Save( $NewConfig )
      Set-AzureVNetConfig -ConfigurationPath $NewConfig -Verbose 
    }
    else
    {
      Write-Warning -Message ( "S2SVPN is up to date: $(Get-Date)" )
    }
    
  }
  catch {
    
    Write-Warning -Message 'Cannot connect to Azure'
  }
  
}