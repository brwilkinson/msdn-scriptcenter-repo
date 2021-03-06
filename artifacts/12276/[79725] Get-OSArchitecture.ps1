function global:Get-OSArchitecture {

#Requires -Version 2.0
[CmdletBinding()]
 Param 
   (
    [Parameter(Mandatory=$false,
               Position=1,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [String[]]$ComputerName = $env:COMPUTERNAME      
   )#End Param 

Begin
{
 Write-Verbose "Retrieving Computer Info . . ."
}
Process
{
$ComputerName | foreach { 
$ErrorActionPreference = 0
$Computer = $_
$Windir,$OSArchitecture,$OSVersion = Get-WmiObject -class Win32_OperatingSystem -ComputerName $_ | 
    foreach {$_.WindowsDirectory,$_.OSArchitecture,$_.Version}
$SysDrive = ($Windir -split ":")[0] + "$"
# $OSVersion[0]
# $OSArchitecture is only suppored on OSVersion -ge 6
# I was going to test for that, however now I just test if $OSArchitecture -eq $True
Write-Verbose "Operating System version on $Computer is: $OSVersion"
if ($OSArchitecture)
    {
        New-Object PSObject -Property @{ 
        Hostname=$Computer
        OSArchitecture=$OSArchitecture
        SysDrive=$SysDrive
        OSVersion=$OSVersion
        WinDir=$WinDir
        }
    }
else
    {
        # check the program files directory
        write-verbose "System Drive on $Computer is: $SysDrive"
        $x64 =  "\\$Computer\" + $SysDrive + "\Program Files (x86)"
        if (test-path ("\\$Computer\" + $SysDrive))
            {
                if (test-path $x64)
                    {
                        New-Object PSObject -Property @{ 
                        Hostname=$Computer
                        OSArchitecture="64-bit"
                        SysDrive=$SysDrive
                        OSVersion=$OSVersion
                        WinDir=$WinDir
                        }
                    }
                elseif (!(test-path $x64))
                    {
                        New-Object PSObject -Property @{ 
                        Hostname=$Computer
                        OSArchitecture="32-bit"
                        SysDrive=$SysDrive
                        OSVersion=$OSVersion
                        WinDir=$WinDir
                        }
                    }
            }
        else {"Something wrong determining the System Drive"} 
    }
} | select Hostname,OSArchitecture,SysDrive,WinDir,OSVersion

}#Process            
End            
{   

}#End 


}#Get-Architecture