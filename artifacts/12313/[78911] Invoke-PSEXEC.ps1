function global:Invoke-PSEXEC {
#Requires -Version 2.0            
[CmdletBinding()]            
 Param             
   (                       
    [Parameter(Mandatory=$true,
               Position=0,                          
               ValueFromPipeline=$true,            
               ValueFromPipelineByPropertyName=$true)]            
    [String[]]$ComputerName,
    [Parameter(Mandatory=$true,
               Position=2,                          
               ValueFromPipeline=$false,            
               ValueFromPipelineByPropertyName=$false)] 
    [String]$Command,
    [String]$File,
    [String]$Params
   )#End Param

Begin            
{            
 Write-Host "`n Running psexec . . . "
 $i = 0            
}#Begin          
Process            
{
    $ComputerName | ForEach-Object {
    $computer = $_
    if ($File)
        {
            $cmd = {psexec.exe /acceptEula \\$Computer -high -f -c $File $Command $Params}
        }
    else
        {
            $cmd = {psexec.exe /acceptEula \\$Computer -high $Command $Params}
        }
    $Result = & $cmd
    $Result | Where-Object {$_}
    }
}#Process
End
{

}#End

}#Invoke-PSEXEC