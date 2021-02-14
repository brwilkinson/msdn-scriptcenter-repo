Function Global:Set-LocalGroup {

#Require -Version 2.0 -Modules ActiveDirectory            
[CmdletBinding()]            
 Param             
   (                       
    # A ComputerName to add the Trustee as Local Admin
    [Parameter(Mandatory=$true, 
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true, 
                Position=1)]
    [String[]]$ComputerName,
    
    [Parameter(Mandatory=$true,
               Position=2)]
    [Alias("Identity")]
    [String]$Trustee,

    [Parameter(Position=3)]
    [String]$LocalGroup = "Administrators"
   )#End Param

Begin
{
    # Load the required Module
    Import-Module -Name ActiveDirectory -ErrorAction SilentlyContinue

    # Test if the ActiveDirectory Module is loaded, or else Exit
    Try {
        Get-Module -Name ActiveDirectory -ErrorAction Stop | Out-Null
       }
    Catch {
        Write-Verbose -Message "You need the ActiveDirectory Module to run this script, now exiting." -Verbose
        Break
       }

    Try {
        $SamAccountName = Get-ADUser -Identity $Trustee -ErrorAction Stop | Select-Object SamAccountName
    }
    Catch {
        Write-Verbose -Message "$Trustee is not a valid SamAccountName"
        Break
    }

}#begin
         
Process            
{
    # Add a $Trustee to a local group on $ComputerName
    $ComputerName | ForEach-Object {
        
        $Computer = $_
        [String]$DomainName = ([ADSI]"").name
    
        try {
        
            ([ADSI]"WinNT://$Computer/$LocalGroup,group").Add("WinNT://$DomainName/$SamAccountName")
        }
        catch {

            Write-Verbose -Message "Cannot add Identity `"$Trustee`" to Local Group, please provide correct SamAccountName" -Verbose

    }
        
    }#ForEach-Object(Trustee)

}#Process
End
{

}#End


}#Set-LocalAdmin

