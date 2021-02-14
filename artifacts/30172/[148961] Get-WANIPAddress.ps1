Function Get-WANIPAddress {
param (
        # This lookup uses the html class, which may change.
        # we will just check both known classes for this.
        [String[]]$Class = ('b_focusTextLarge','b_focusTextMedium')
        )
Try {
      $Query = 'https://www.bing.com/search?q=IP+Address'
      $a = Invoke-WebRequest -Uri $Query

      [IPAddress]$WANIP = $class | ForEach-Object {
        $a.ParsedHtml.body.getElementsByClassName( $_ )
      } | Select-Object -ExpandProperty innerText
        
      $IP = Get-NetIPConfiguration -Detailed | Where-Object -Property IPv4DefaultGateway
      
      $LANIP = $IP | Select-Object -ExpandProperty IPv4Address -First 1

      #$80 = Test-NetConnection -ComputerName $IP.IPv4DefaultGateway.NextHop -CommonTCPPort HTTP
      #$443 = Test-NetConnection -ComputerName $IP.IPv4DefaultGateway.NextHop -Port 443

      [pscustomobject]@{
            LANIPAddress = $LANIP
            LANGateway   = $IP.IPv4DefaultGateway[0].NextHop
            WANIPAddress = $WANIP.IPAddressToString
            }
} 
Catch {

      Write-Warning $_
}      
      
}

