Function global:Get-LocalGroup{

#Requires -Version 2.0            
[CmdletBinding()]            
 Param             
   (                       
    [Parameter(Mandatory=$false,
               Position=1,                          
               ValueFromPipeline=$true,            
               ValueFromPipelineByPropertyName=$true)]            
    [String[]]$ComputerName = "localhost",
    [String]$LocalGroup = "Administrators",
    [Switch]$Export
   )#End Param

Begin            
{            
      $MemberNames = @()     
}#Begin          
Process            
{

    $ComputerName | ForEach-Object {
    $Computer = $_
    	$Group = [ADSI]"WinNT://$Computer/$LocalGroup,group"
    	
        # if statement to check for errors if the local group does not exist.
        if ($Group.Path)
            {
                $Members = @($Group.psbase.Invoke("Members"))
    	        [Array]$MemberNames = $Members | 
                    ForEach-Object {$_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)}


                if ($Export)
                    {
                     $Hash = @{
                        Server= $Computer.ToUpper()
                        LocalGroup = $LocalGroup
                        Groups= $MemberNames -join ", "
                        }
                    }
                else    
                   {
                     $Hash = @{
                        Server     = $Computer.ToUpper()
                        LocalGroup = $LocalGroup
                        Groups     = $MemberNames 
                        }
                   }
       
                New-Object PSObject -Property $Hash | 
                    Select Server,LocalGroup,Groups
            }
        else
            {
                Write-Verbose -Message "Group `"$LocalGroup`" does not exist on `"$Computer`"" -Verbose
            }
    }#Foreach-Object(ComputerName)
    
}#Process 
End
{

}#End


}#Get-LocalAdmin


