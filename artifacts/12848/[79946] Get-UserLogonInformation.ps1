function Get-UserLogonInformation {

#Requires -Version 2.0            
[CmdletBinding()]            
 Param             
   (                       
    [Parameter(Mandatory=$true,
               Position=1,                          
               ValueFromPipeline=$false,            
               ValueFromPipelineByPropertyName=$false)]            
    [String]$User,
    [Float]$TimeOffsetfromGMT = -5
   )#End Param

Begin            
{            
 Write-Host "`n Checking domain controllers for last Password/logon/Logoff times . . . `n"
 $i = 0            
}#Begin          
Process            
{
    $LogonHistory = Get-DomainController | ForEach-Object {
    $DC = $_
    Connect-QADService -Service $_ | Out-Null
    Get-QADUser -Identity $User -IncludedProperties 'lockoutTime', 'badPasswordTime','badPwdCount','LastLogon','LastLogoff' | 
        ForEach-Object {
    $hash = @{
    BadPassTime     =(Get-Date $_.badPasswordTime -ErrorAction 0).addhours($TimeOffsetfromGMT)
    badPwdCount     =($_.badPwdCount)
    DomainController=$DC
    LockoutTime     =($_.lockoutTime)
    LastLogon       =$(if ($_.LastLogon){$_.LastLogon}else{"Unknown"})
    LastLogoff      =$(if ($_.LastLogoff){$_.LastLogoff}else{"Unknown"})
    }
    New-Object PSOBJECT -Property $hash
    }#Foreach-Object(User)
    }#Foreach-Object(DomainControllers)

    $Info = @($LogonHistory | Select-Object DomainController,BadPassTime,BadPwdCount,LockoutTime | Sort-Object BadPassTime -Descending)[0]
    $LastLogon = @($LogonHistory | Select-Object -ExpandProperty LastLogon -ErrorAction 0  | Sort-Object -Descending)[0]
    $LastLogoff = @($LogonHistory | Select-Object -ExpandProperty LastLogoff -ErrorAction 0 | Sort-Object -Descending)[0]
    
    if ($LastLogon)
        {
            $Info | Add-Member -MemberType NoteProperty -Name LastLogon -Value $LastLogon -ErrorAction 0
        }
    
    if ($LastLogoff)
        {    
            $Info | Add-Member -MemberType NoteProperty -Name LastLogoff -Value $LastLogoff -ErrorAction 0
        }       
    $Info

}#Process
End
{
    $DC = $Null
    Connect-QADService -Service "favDC01.domain.org" | Out-Null
}#End

}#Get-UserLogonInformation
