<#
.Synopsis
   Retrieves the LastUseTime of the user profile
.DESCRIPTION
   Retrieves the LastUseTime of the user profile using the WMI class Win32_UserProfile. 
   This class only works on: Server2008,VistaSp1+ machines.
.EXAMPLE
   "Server1","Server2" | Get-UserLastLogin
.EXAMPLE
   Get-UserLastLogin -ComputerName Server1,Server2
#>

function Get-UserLastLogin { 
param( 
[String[]]$ComputerName = $ENV:ComputerName  
) 
begin {
    $NS = "root\CIMv2"
}
Process { 
$ComputerName | ForEach-Object { 
$Computer = $_ 

Get-WmiObject -Class Win32_UserProfile -Namespace $NS -ComputerName $Computer | 
Where-Object {!$_.Special} |
ForEach-Object {

$UserDir = Split-Path -Path $_.LocalPath -Leaf
$Lastuse = $_.ConvertToDateTime($_.LastUseTime)
$_ | Add-Member -MemberType NoteProperty -Name UserDir -Value $UserDir
$_ | Add-Member -MemberType NoteProperty -Name LastUse -Value $Lastuse
$_ | Select-Object PSComputerName,UserDir,LastUse,LocalPath # ,sid, special

} 
}#Foreach-Object(Computer) 
}#Process

}#Get-UserLastLogin