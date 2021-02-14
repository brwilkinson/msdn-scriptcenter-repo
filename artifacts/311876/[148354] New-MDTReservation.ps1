Function New-MDTReservation {
[cmdletbinding()]
param (
        [String]$MACAddress,
        [String]$ComputerName,
        
        [parameter()]
        [validateset('2012R2FULL')]
        [String]$OperatingSystem = '2012R2FULL'
      )

begin {
    gmo mdtdb -ListAvailable | ipmo
    mdtdb\Connect-MDTDatabase -sqlServer mssql -database mdtdb | Out-Null

}
process {    
    # regular expression to add the - in between the mac address from 00155D010B4A to 00-15-5D-01-0B-4A
    $MACAddress -match '(?<1>(\w{2}))(?<2>(\w{2}))(?<3>(\w{2}))(?<4>(\w{2}))(?<5>(\w{2}))(?<6>(\w{2}))' | Out-Null
    $newMac = (1..6 | foreach { $Matches[$_] }) -join ':'

    $CN = mdtdb\New-MDTComputer -macAddress $newMac -description $ComputerName -settings @{
        ComputerName        = $ComputerName
        OSDComputerName     = $ComputerName
        #SkipBDDWelcome      = 'Yes'
        } 

    mdtdb\Get-MDTComputer -macAddress $newMac | 
        mdtdb\Set-MDTComputerRole -roles $OperatingSystem,JoinDomain | 
        select ComputerName, osinstall, MacAddress
 
}
}