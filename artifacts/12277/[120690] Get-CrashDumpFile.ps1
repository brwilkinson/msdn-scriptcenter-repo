function global:Get-CrashDumpFile {

#Requires -Version 2.0
[CmdletBinding()]
 Param 
   (
    [Parameter(Position=1,
               ValueFromPipeline=$true,
               ValueFromPipelineByPropertyName=$true)]
    [String[]]$ComputerName = $env:COMPUTERNAME     
   )#End Param 

Begin
{
 Write-host "`nRetrieving Computer Info . . ."
}
Process
{
$ComputerName | foreach { 
$ErrorActionPreference = 0
$Server = $_

# I just use this other script to get this information
# http://gallery.technet.microsoft.com/scriptcenter/26539b66-13a7-44f6-9adb-886c54fc141f
$SysDrive = (Get-OSArchitecture -ComputerName $server).SysDrive

$path2 =  "\\$Server\" + $SysDrive + "\Windows\Minidump\*.dmp"
if (test-path $path2)
    {
        gci $path2 -Force
    }
$path2 =  "\\$Server\" + $SysDrive + "\Windows\*.dmp"
    if (test-path $path2)
    {
        gci $path2 -Force
    }

# I just use this other script to get this information
# http://gallery.technet.microsoft.com/scriptcenter/74884d85-c0b5-446a-be04-3d411a6dce2f
Get-VolumeWin32 -ComputerName $_ -Creds $Creds | % {
    $drive = ($_.Name).split(":")[0] + "$"
    $path3 = "\\$Server\" + $drive 
        if (test-path $path3)
        {
            if (gci $path3 -Force -Filter "dedicateddumpfile.sys")
                {
                    $Path4 = $Path3 + "\*.dmp"
                    gci $path4 -force
                }
        }
    }
}
}#Process            
End            
{   

}#End 


}#Get-CrashDumpFiles